---
name: "capture-screenshot"
description: "Capture a Chrome window on macOS and crop it into a publication-ready JPEG (Save Path Default: ask the user). Use this skill whenever a screenshot of a web page is needed for a blog post, document, or report — including 'スクショ撮って', '画面キャプチャして', 'この画面を記事用に撮って', 'ブラウザの画面を貼りたい', or when another skill delegates screenshot capture. It handles multi-window disambiguation, window resizing for readable aspect ratio, cropping away browser chrome, red-box annotation, and a visual check for confidential information with black-box masking of anything that must not be published."
argument-hint: "[撮影対象URL] [切り出しJPEGの保存先パス] [赤枠で強調する箇所]"
---

macOS 上の Chrome の画面を撮影し、掲載用の JPEG に切り出す手順です。

# 入力

呼び出し元（ユーザーまたは他スキル）から以下を受け取ります。不足しているものは撮影に入る前に確認してください。

| 入力 | 内容 | 未指定時 |
| --- | --- | --- |
| 撮影対象 | URL、および撮影したい表示状態 | AskUserQuestion で確認する |
| 保存先パス | 切り出した JPEG の出力先（ファイル名まで） | AskUserQuestion で確認する |
| 赤枠で強調する箇所 | 画像内で注目させたい箇所 | 強調なしで撮る |
| 排除対象 | 画像に写ってはいけない情報（顧客名・案件名・社内 URL 等） | 業務情報一般を排除対象として扱う |

# 1. 撮影対象を表示する

Claude in Chrome の `navigate` / `get_page_text` / `read_page` で対象ページを開き、狙った表示になっているかを撮影前に読んで確認します。

この構成では `computer` を PreToolUse フック（`~/dotfiles/genai/hooks/chrome-tool-guard.sh`）で絞っており、ページを変えない操作（`scroll`・`scroll_to`・`screenshot`・`zoom`・`hover`・`wait`）だけが通ります。撮る範囲へのスクロール、撮影前の `screenshot` での収まりの確認、`hover` でカーソルを本文の外へ逃がす操作はこちらで行ってください。

伝えたい単位（グラフと AI のコメント、表とその見出し等）が 1 画面に収まらない場合は、`javascript_tool` で `document.body.style.zoom='80%'` を代入して縮小します。収まらなければ 70%・60% と下げ、50% 以下は掲載幅で文字が読めなくなるので使わず、複数枚に分けてください。
フックが通すのは zoom の単純な代入だけで、`setTimeout` 等を含むスクリプトは拒否されます。zoom は `navigate` やユーザーのクリックによる画面遷移で 100% に戻るため、遷移のたびに代入し直してください。
撮影前に `hover` で座標 (5,5) 付近へカーソルを逃がし、ツールチップやホバー表示が写り込まないようにします。

タブ・プルダウンの切り替えで表示が変わる画面は、撮る前に最下部までスクロールして全体を読み、どの表示を何枚に分けて撮るかを決めてから撮影に入ってください。途中で撮り漏れに気付くと、番号の振り直しと撮り直しが発生します。

クリック・入力を伴う準備（リポジトリ作成・PR 作成・フォーム送信・タブの切り替え等）はフックで拒否されるので、ユーザーに手動操作を依頼してください。依頼は次の形にします。

- 事前入力済み URL を `navigate` で開いた上で、押すボタンだけを伝える（GitHub なら `https://github.com/new?name=...&visibility=private`、PR は `.../compare/<base>...<head>?quick_pull=1&title=...&body=...`）
- 入力値を URL に載せられない箇所だけ、貼り付ける文字列をそのまま提示する

# 2. 撮影する

Chrome のウィンドウは複数開いている前提で扱います。`window 1` は撮影対象とは別のウィンドウを指す事があるため、URL で特定したウィンドウ ID を 4 段階すべてで使い回してください。

AppleScript は `scripts/` のスクリプトにまとめてあり、以下のコマンドは書かれたとおりの形（`bash ~/.claude/skills/...`）で実行してください。この形で `permissions.allow` に登録してあるため、auto モードの分類器を通らずにすぐ実行されます。

## 2-1. 対象ウィンドウを特定し、元の bounds を控える

```bash
bash ~/.claude/skills/capture-screenshot/scripts/chrome_windows.sh
```

1 行に 1 ウィンドウずつ、`<ID> | <x1>,<y1>,<x2>,<y2> | <アクティブなタブの URL>` の形で出ます。

## 2-2. ウィンドウを狭める

`mcp__claude-in-chrome__resize_window` に対象タブの `tabId` と `width` / `height` を渡します（目安は 1000x900）。

GitHub のようにコンテンツを幅いっぱいに配置するページを 1920pt のまま撮ると、右半分が余白の極端な横長になり、掲載幅に縮小した時点で文字が読めなくなります。1920pt では 7.5:1、1000pt では 4.1:1 になり、掲載幅 800px での縮小率が 0.21 から 0.41 へ改善します。切り出しでは比率を救えない（必要範囲を残すと横長が悪化する）ため、撮影時点で狭めてください。

ただし、SaaS の管理画面のようにページの最小幅が狭めた幅を超える場合は、右側が切れたり横スクロールが出たりします。その時は狭めずに画面幅いっぱい（例: 1512x949 のディスプレイなら全体）で撮り、手順 1 の zoom で収まりを調整してください。

`tabId` とウィンドウの対応を取り違えて別のウィンドウが縮む場合があります。2-3 の撮影スクリプトに狙ったサイズを渡すと、対象ウィンドウがそのサイズになっていない時は撮らずに終了コード 3 で全ウィンドウの一覧を出すので、別のウィンドウが縮んでいたら対象が変わるまで `resize_window` を呼び直してください。

## 2-3. 前面に出して撮影する

```bash
bash ~/.claude/skills/capture-screenshot/scripts/chrome_capture.sh <ウィンドウID> "" <幅> <高さ>
```

- 第 2 引数は保存先の PNG パス。`""` なら macOS 標準のスクリーンショットと同じ `${HOME}/Pictures/ScreenShot/スクリーンショット <日時>.png` に保存する
- 第 3・4 引数は 2-2 で狙ったサイズ（pt）。画面幅いっぱいで撮る場合も、2-1 の bounds から求めた幅と高さを渡す
- スクリプトは ID 指定でウィンドウを前面へ出し、Chrome が最前面になるのを待ってから撮る（固定の待ち時間は置かない）。出力の bounds・PNG の寸法・px/pt の比は手順 3 の座標計算に使う
- `warning: Chrome did not come to the front` が出たら、他のアプリのウィンドウが写り込んでいないかを PNG で確かめる

ウィンドウが重なっていると背面のものが写るため、ID 指定で前面へ出してから撮ります。比較画像は同じウィンドウサイズのまま連続で撮り、途中でサイズを変えないでください。

`screencapture` が写すのはウィンドウの**アクティブなタブ**であり、Claude in Chrome が操作中のタブとは限りません。ユーザーが同じウィンドウの別タブを触っていると、そのタブや、スクロール前の状態が写ります。2-1 の出力の URL が撮影対象のものか確かめ、違えば撮影対象のタブをクリックするようユーザーに依頼してください。撮った画像は毎回 Read で見て、狙った画面とスクロール位置かを確かめます。

- 保存先とファイル名は macOS 標準のスクリーンショットと同じ形式に揃える
- この PNG はタブバー・ブックマークバーを含むウィンドウ全体であり、掲載しない業務情報が写っている。掲載するのは手順 3 で切り出した JPEG だけであり、元 PNG は `${HOME}/Pictures/ScreenShot/` に残るため、手順 4 でパスを報告して削除はユーザーの判断に委ねる
- `could not create image from display` は画面収録権限の不足。`$TERM_PROGRAM` と親プロセスから実行元アプリを特定し、システム設定 → プライバシーとセキュリティ → 画面収録 での許可をユーザーに依頼する（権限付与は Claude では行わない）

## 2-4. 元のウィンドウ配置に戻す

```bash
bash ~/.claude/skills/capture-screenshot/scripts/chrome_restore.sh <ウィンドウID> <x1> <y1> <x2> <y2>
```

`resize_window` は幅と高さしか扱えず位置を戻せないため、復元は AppleScript の `set bounds` で行います。スクリプトは戻した後に全ウィンドウの一覧を出すので、それで復元を確認してください。2-2 で取り違えて動かした他のウィンドウがあれば、同じスクリプトでそれも戻します。

# 3. 変換して保存先へ切り出す

PNG を Read すると元画像の寸法と表示倍率が返るので、それを使って掲載したい領域の座標を算出し、ffmpeg で切り出して JPEG に変換します。

切り出す座標は、`screenshot` で見たビューポート座標から計算で求めます。目測で合わせると、ずれるたびに全画面 PNG の Read と切り出しをやり直すことになるためです。

| 記号 | 値 | 出どころ |
| --- | --- | --- |
| `W`・`H` | ウィンドウの幅と高さ（pt） | 2-3 の出力の bounds |
| `r` | PNG の px/pt の比（Retina は 2） | 2-3 の出力 |
| `sw`・`sh` | `screenshot` 画像の幅と高さ（px） | `screenshot` の結果 |

1. ビューポートの縮尺 `s = W / sw` を求める（`screenshot` が縮小されていなければ 1）
2. ブラウザ UI（タブバー・アドレスバー・ブックマークバー・Claude in Chrome のデバッグバナー）の高さを `top = H - sh × s` で求める。macOS の Chrome はウィンドウの左右と下に枠を持たないため、上端以外にオフセットはない
3. ビューポート座標 `(vx, vy)` は PNG 上で `PNG x = vx × s × r`、`PNG y = (top + vy × s) × r` になる

例: 1512x949 pt のウィンドウで `screenshot` が 1512x806 なら、`top = 143` pt、PNG 上の上端オフセットは 286 px になる。
同じウィンドウサイズで撮る間は `top` が変わらないので、1 度求めれば使い回せます。
切り出した JPEG を確かめて数 px ずれている場合だけ、ページ上の目立つ要素の位置を `screenshot` と PNG で見比べて補正してください。

```bash
ffmpeg -loglevel error -y -i "<PNG パス>" -vf "crop=<w>:<h>:<x>:<y>" -q:v 2 "<保存先パス>"
```

強調したい箇所がある場合は、`crop` の後ろに `drawbox` をカンマで繋いで赤枠を重ねます（座標は切り出し後の画像が基準。複数箇所はカンマで並べる）。

```bash
-vf "crop=<w>:<h>:<x>:<y>,drawbox=x=<x>:y=<y>:w=<w>:h=<h>:color=red@1.0:t=5"
```

機密情報を隠す場合は、同じ `drawbox` を `color=black:t=fill` にして塗りつぶします。赤枠と黒塗りが同居する場合は同じ `-vf` チェーンにカンマで並べます。

```bash
-vf "crop=<w>:<h>:<x>:<y>,drawbox=x=<x>:y=<y>:w=<w>:h=<h>:color=black:t=fill"
```

- 保存先パスとファイル名の規約は呼び出し元が決める。入力で受け取ったパスをそのまま使う
- 赤枠は入力で指定された箇所だけに絞る
- ブラウザのタブバー・ブックマークバー・拡張機能アイコン・通知バナーは切り落とし、ページ本文の領域だけを残す（タブのタイトルに業務情報が写るため）
- Claude in Chrome が操作中のタブには、ページ表示領域の上・左右・下の縁に赤い光が出る。公式に消す設定は無いため、切り出しで避ける。光はページ表示領域の各辺から約 48px（Retina の実寸）で白に消えるので、切り出す範囲はどの辺からも 48px 以上内側に取る（左端なら `x` を 48 以上、右端なら `x + w` を画像幅 - 48 以下にする）
- 比較画像は左端・幅を揃え、同じ箇所を同じ大きさで切り出す
- **変換後の JPEG を Read で目視し、排除対象が写っていないか確認する**。テキストの grep 照合は画像を見ないため、画像の機密チェックはこの目視が最後の砦になる
- 排除対象が写っていた場合は、写っている場所で対処を分けて**元 PNG から変換をやり直す**（JPEG を再エンコードすると二重圧縮で画質が落ちるため、出力 JPEG に上書き加工はしない）
  - 掲載領域の端にあり、切り落としても伝えたい内容が成立する場合は `crop` の座標を詰める
  - 本文領域の中にあって切り落とせない場合は `drawbox` の黒塗りでマスクする
- 黒塗り後は再度 Read で目視し、文字がマスクからはみ出していないか確認する。はみ出していたら座標・サイズを広げて変換し直し、排除対象が読めなくなるまで繰り返す

# 4. 報告

以下を呼び出し元へ報告して完了とします。

- 切り出した JPEG のパス一覧
- 黒塗りでマスクした画像と、マスクした箇所に何が写っていたか（公開前のマスク漏れ・過剰マスクをユーザーが判断できるようにするため）
- 撮影した元 PNG（`${HOME}/Pictures/ScreenShot/` 配下）のパス一覧と、業務情報を含む画面全体が残っているため削除はユーザー判断である旨
- ウィンドウ配置を元に戻した旨（他のウィンドウを動かした場合はそれも含む）
