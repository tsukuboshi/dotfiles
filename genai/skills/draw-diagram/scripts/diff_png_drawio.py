""".drawio.png に埋め込まれた図データと .drawio の同名ページをセル単位で比べる。

使い方:
    diff_png_drawio.py <file.drawio.png> <file.drawio>

- PNG の tEXt / zTXt チャンクから図データ（mxfile）を取り出し、
  .drawio の中から同じ id（なければ同じ名前）のページを探して比べる
- セルは id で突き合わせ、追加・削除と、属性・mxGeometry の差分を出す。
  インデントなど XML の書式の違いは無視する
- 差分がなければ「差分なし」と出す
"""

import argparse
import pyexpat
import struct
import sys
import urllib.parse
import xml.etree.ElementTree as ET
import zlib
from pathlib import Path

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


def embedded_mxfile(png: Path) -> ET.Element:
    data = png.read_bytes()
    i = 8
    while i < len(data):
        n = struct.unpack(">I", data[i : i + 4])[0]
        ctype = data[i + 4 : i + 8]
        body = data[i + 8 : i + 8 + n]
        i += 12 + n
        if ctype not in (b"tEXt", b"zTXt"):
            continue
        keyword, _, value = body.partition(b"\x00")
        if keyword not in (b"mxfile", b"mxGraphModel"):
            continue
        if ctype == b"zTXt":
            value = zlib.decompress(value[1:])
        xml = urllib.parse.unquote(value.decode("latin-1"))
        return ET.fromstring(xml)  # noqa: S314 -- main で require_safe_expat を済ませている
    sys.exit(f"{png} に図データが埋め込まれていない")


def describe(cell: ET.Element) -> str:
    value = (cell.get("value") or "").replace("\n", " ")
    return f"{cell.get('id')} 「{value[:60]}」 parent={cell.get('parent')}"


def geometry(cell: ET.Element) -> str:
    geo = cell.find("mxGeometry")
    if geo is None:
        return ""
    # 子要素（経由点・sourcePoint など）も書式を除いて比べる
    for el in geo.iter():
        el.text = el.tail = None
    return ET.tostring(geo, encoding="unicode")


def main() -> None:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("png", type=Path)
    parser.add_argument("drawio", type=Path)
    args = parser.parse_args()

    require_safe_expat()
    png_page = embedded_mxfile(args.png).find("diagram")
    pages = ET.parse(args.drawio).getroot().findall("diagram")  # noqa: S314 -- 同上
    page = next(
        (p for p in pages if p.get("id") == png_page.get("id")),
        next((p for p in pages if p.get("name") == png_page.get("name")), None),
    )
    if page is None:
        sys.exit(f"{args.drawio} にページ「{png_page.get('name')}」がない")

    png_cells = {c.get("id"): c for c in png_page.iter("mxCell")}
    cells = {c.get("id"): c for c in page.iter("mxCell")}
    print(f"ページ「{page.get('name')}」: PNG 側 → .drawio 側")
    found = False
    for cid in png_cells.keys() - cells.keys():
        print(f"PNG のみ     {describe(png_cells[cid])}")
        found = True
    for cid in cells.keys() - png_cells.keys():
        print(f".drawio のみ {describe(cells[cid])}")
        found = True
    for cid in png_cells.keys() & cells.keys():
        a, b = png_cells[cid], cells[cid]
        changed = [
            k for k in sorted(set(a.attrib) | set(b.attrib)) if a.get(k) != b.get(k)
        ]
        geo_a, geo_b = geometry(a), geometry(b)
        if not changed and geo_a == geo_b:
            continue
        found = True
        print(f"差分あり     {describe(b)}")
        for key in changed:
            print(f"    {key}: {a.get(key)} → {b.get(key)}")
        if geo_a != geo_b:
            print(f"    geometry: {geo_a} → {geo_b}")
    if not found:
        print("差分なし")


if __name__ == "__main__":
    main()
