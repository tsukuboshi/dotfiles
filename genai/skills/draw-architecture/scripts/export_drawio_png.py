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
import shutil
import struct
import subprocess
import sys
import urllib.parse
import xml.etree.ElementTree as ET
import zlib
from pathlib import Path

DRAWIO_APP = "/Applications/draw.io.app/Contents/MacOS/draw.io"


def find_drawio() -> str:
    found = shutil.which("drawio") or (
        DRAWIO_APP if Path(DRAWIO_APP).exists() else None
    )
    if not found:
        sys.exit("drawio CLI が見つからない。`brew install --cask drawio` で入れる")
    return found


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

    root = ET.parse(args.drawio).getroot()
    diagrams = root.findall("diagram")
    names = args.names.split(",") if args.names else []
    if len(diagrams) > 1 and len(names) != len(diagrams):
        pages = ", ".join(f"{i}:{d.get('name')}" for i, d in enumerate(diagrams, 1))
        sys.exit(
            f"{len(diagrams)} ページある（{pages}）。--names で同じ数の接尾辞を渡す"
        )

    stem = args.drawio.name.removesuffix(".drawio")
    out_dir = args.out_dir or args.drawio.parent
    drawio = find_drawio()
    for index, diagram in enumerate(diagrams, 1):
        png = out_dir / (
            f"{stem}-{names[index - 1]}.drawio.png" if names else f"{stem}.drawio.png"
        )
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
            str(png),
            str(args.drawio),
        ]
        subprocess.run(cmd, check=True, capture_output=True, timeout=120)
        embed_mxfile(png, page_xml(root, diagram))
        print(f"{png}  <- page {index}「{diagram.get('name')}」")


if __name__ == "__main__":
    main()
