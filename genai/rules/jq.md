---
paths:
  - "**/*.{json,jsonl}"
---

# jq

中身を知らない JSON は、Python を書かずに jq で構造から見る。jq は日本語をエスケープせずに出す。

構造の要約（値を型名に、配列を `[件数, 要素の形]` に置き換える。オブジェクトの配列は全要素のキーを合わせ、型が食い違うキーは後の要素の型になる）:

```bash
jq -c 'def s: if type=="object" then with_entries(.value|=s)
  elif type=="array" then (if length==0 then [] else [length, (map(s)
    | if all(type=="object") then reduce .[] as $x ({}; . * $x) else .[0] end)] end)
  else type end; s' file.json
```

JSON Lines は同じ式で 1 行ずつ要約し、`| sort | uniq -c` で行の形ごとの件数にする。標準入力（`curl ... | jq ...`）にも同じ式が使える。

要素の中身は、構造で見つけたパスを指定し、長さを切って見る: `jq -c '.events[0]' file.json | cut -c1-800`
