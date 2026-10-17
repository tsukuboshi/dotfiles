"""draw.io の .drawio をページごとに .drawio.png へ書き出す。

使い方:
    export_drawio_png.py <file.drawio> [--names dev,ops] [--out-dir DIR]

- 2 倍の解像度・余白 20px で PNG を書き出す（drawio CLI の -s 2 -b 20）
- 図データは tEXt チャンクの "mxfile" キーに URL エンコードして埋め込む。
  draw.io 本体と VS Code 拡張（hediet.vscode-drawio）はこの形式だけを読む。
  CLI の -e は zTXt の "mxGraphModel" に書くため、VS Code 拡張では白紙になる
- 出力名は 1 ページなら <stem>.drawio.png、複数ページなら <stem>-<name>.drawio.png
"""

import argparse
import os
import pyexpat
import shutil
import struct
import subprocess
import sys
import urllib.parse
import xml.etree.ElementTree as ET
import zlib
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

DRAWIO_APP = "/Applications/draw.io.app/Contents/MacOS/draw.io"

# xml.etree は外部エンティティを解決せず、expat 2.7.2 以降は Billion Laughs・
# Quadratic Blowup・巨大トークンの攻撃を expat 自身が抑える
# （https://docs.python.org/3/library/xml.html#xml-vulnerabilities）。
# defusedxml は python3 -I では読み込めないため、expat の版を確かめて標準のパーサーを使う
MIN_EXPAT = (2, 7, 2)


def require_safe_expat() -> None:
    if pyexpat.version_info < MIN_EXPAT:
        sys.exit(
            f"expat {pyexpat.EXPAT_VERSION} は XML の展開攻撃を防げない。"
            "expat 2.7.2 以降の Python で実行する"
        )


def find_drawio() -> str:
    found = shutil.which("drawio") or (
        DRAWIO_APP if Path(DRAWIO_APP).exists() else None
    )
    if not found or not os.access(found, os.X_OK):
        sys.exit("drawio CLI が見つからない。`brew install --cask drawio` で入れる")
    return str(Path(found).resolve())


def page_xml(root: ET.Element, diagram: ET.Element) -> str:
    mxfile = ET.Element("mxfile", dict(root.attrib))
    mxfile.append(diagram)
    return ET.tostring(mxfile, encoding="unicode")


def png_chunk(ctype: bytes, data: bytes) -> bytes:
    crc = zlib.crc32(ctype + data) & 0xFFFFFFFF
    return struct.pack(">I", len(data)) + ctype + data + struct.pack(">I", crc)


def embed_mxfile(png: Path, xml: str) -> None:
    # draw.io は encodeURIComponent 相当でエンコードする
    text = urllib.parse.quote(xml, safe="-_.!~*'()")
    data = png.read_bytes()
    out, i = [data[:8]], 8
    while i < len(data):
        n = struct.unpack(">I", data[i : i + 4])[0]
        ctype = data[i + 4 : i + 8]
        keyword = data[i + 8 : i + 8 + n].split(b"\x00", 1)[0]
        is_diagram = ctype in (b"tEXt", b"zTXt") and keyword in (
            b"mxfile",
            b"mxGraphModel",
        )
        if not is_diagram:
            out.append(data[i : i + 12 + n])
            if ctype == b"IHDR":
                out.append(png_chunk(b"tEXt", b"mxfile\x00" + text.encode("latin-1")))
        i += 12 + n
    png.write_bytes(b"".join(out))


def main() -> None:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("drawio", type=Path)
    parser.add_argument(
        "--names",
        help="ページごとの出力名の接尾辞をカンマ区切りで（複数ページでは必須）",
    )
    parser.add_argument(
        "--out-dir", type=Path, help="出力先（既定は .drawio と同じディレクトリ）"
    )
    args = parser.parse_args()

    # drawio CLI に渡す前に、入力が実在する .drawio であることを確かめる
    if not (args.drawio.is_file() and args.drawio.name.endswith(".drawio")):
        sys.exit(f"{args.drawio} は .drawio のファイルではない")
    drawio_path = args.drawio.resolve()

    require_safe_expat()
    root = ET.parse(drawio_path).getroot()  # noqa: S314 -- require_safe_expat で expat の版を確かめている
    diagrams = root.findall("diagram")
    names = args.names.split(",") if args.names else []
    if len(diagrams) > 1 and len(names) != len(diagrams):
        pages = ", ".join(f"{i}:{d.get('name')}" for i, d in enumerate(diagrams, 1))
        sys.exit(
            f"{len(diagrams)} ページある（{pages}）。--names で同じ数の接尾辞を渡す"
        )

    stem = drawio_path.name.removesuffix(".drawio")
    out_dir = (args.out_dir or drawio_path.parent).resolve()
    drawio = find_drawio()
    pngs = [
        out_dir / (f"{stem}-{names[i]}.drawio.png" if names else f"{stem}.drawio.png")
        for i in range(len(diagrams))
    ]

    def export_page(index: int) -> None:
        # ページ番号は 1 始まり（drawio v27.0.2 以降）
        cmd = [
            drawio,
            "-x",
            "-f",
            "png",
            "-s",
            "2",
            "-b",
            "20",
            "-p",
            str(index),
            "-o",
            str(pngs[index - 1]),
            str(drawio_path),
        ]
        # shell を通さない引数リストで、実行ファイルと入力は検証済み
        subprocess.run(cmd, check=True, capture_output=True, timeout=120)  # noqa: S603

    # drawio CLI は PNG を 1 起動 1 ページでしか書き出せず、1 ページに 1〜2 秒かかる。
    # 同時に起動しても衝突せず出力も同じなので、ページごとの起動を並列に回す
    # （6 ページの図で、順に起動して 10 秒 → 並列で 3〜4 秒）
    workers = min(len(diagrams), os.cpu_count() or 1)
    with ThreadPoolExecutor(max_workers=workers) as pool:
        list(pool.map(export_page, range(1, len(diagrams) + 1)))

    for index, (diagram, png) in enumerate(zip(diagrams, pngs), 1):
        embed_mxfile(png, page_xml(root, diagram))
        print(f"{png}  <- page {index}「{diagram.get('name')}」")


if __name__ == "__main__":
    main()
