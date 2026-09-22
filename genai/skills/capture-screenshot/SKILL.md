---
name: "capture-screenshot"
description: "Capture a Chrome window on macOS and crop it into a publication-ready JPEG (Save Path Default: ask the user). Use this skill whenever a screenshot of a web page is needed for a blog post, document, or report — including 'スクショ撮って', '画面キャプチャして', 'この画面を記事用に撮って', 'ブラウザの画面を貼りたい', or when another skill delegates screenshot capture. It handles multi-window disambiguation, window resizing for readable aspect ratio, cropping away browser chrome, red-box annotation, and a visual check for confidential information."
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

`computer` / `form_input` が `permissions.deny` にある構成では、クリック・入力を伴う準備（リポジトリ作成・PR 作成・フォーム送信等）はユーザーに手動操作を依頼してください。依頼は次の形にします。

- 事前入力済み URL を `navigate` で開いた上で、押すボタンだけを伝える（GitHub なら `https://github.com/new?name=...&visibility=private`、PR は `.../compare/<base>...<head>?quick_pull=1&title=...&body=...`）
- 入力値を URL に載せられない箇所だけ、貼り付ける文字列をそのまま提示する

# 2. 撮影する

Chrome のウィンドウは複数開いている前提で扱います。`window 1` は撮影対象とは別のウィンドウを指す事があるため、URL で特定したウィンドウ ID を 4 段階すべてで使い回してください。

## 2-1. 対象ウィンドウを特定し、元の bounds を控える

```bash
osascript <<'AS'
tell application "Google Chrome"
  set out to ""
  repeat with w in windows
    set b to bounds of w
    set out to out & (id of w) & " | " & (item 1 of b) & "," & (item 2 of b) & "," & (item 3 of b) & "," & (item 4 of b) & " | " & (URL of active tab of w) & linefeed
  end repeat
  return out
end tell
AS
```

## 2-2. ウィンドウを狭める

`mcp__claude-in-chrome__resize_window` に対象タブの `tabId` と `width` / `height` を渡します（目安は 1000x900）。

GitHub のようにコンテンツを幅いっぱいに配置するページを 1920pt のまま撮ると、右半分が余白の極端な横長になり、掲載幅に縮小した時点で文字が読めなくなります。1920pt では 7.5:1、1000pt では 4.1:1 になり、掲載幅 800px での縮小率が 0.21 から 0.41 へ改善します。切り出しでは比率を救えない（必要範囲を残すと横長が悪化する）ため、撮影時点で狭めてください。

適用後は 2-1 のコマンドで bounds を再確認します。`tabId` とウィンドウの対応を取り違えて別のウィンドウが縮む場合があり、その時は対象が変わるまで呼び直してください。

## 2-3. 前面に出して撮影する

```bash
osascript <<'AS' >/dev/null
tell application "Google Chrome"
  activate
  set index of (first window whose id is <ウィンドウID>) to 1
end tell
AS
sleep 2
screencapture -x -R "<x>,<y>,<w>,<h>" "${HOME}/Pictures/ScreenShot/スクリーンショット $(TZ=Asia/Tokyo date '+%Y-%m-%d %H.%M.%S').png"
```

ウィンドウが重なっていると背面のものが写るため、ID 指定で前面へ出してから撮ります。比較画像は同じウィンドウサイズのまま連続で撮り、途中でサイズを変えないでください。

- 保存先とファイル名は macOS 標準のスクリーンショットと同じ形式に揃える
- この PNG はタブバー・ブックマークバーを含むウィンドウ全体であり、掲載しない業務情報が写っている。掲載するのは手順 3 で切り出した JPEG だけであり、元 PNG は `${HOME}/Pictures/ScreenShot/` に残るため、手順 4 でパスを報告して削除はユーザーの判断に委ねる
- `could not create image from display` は画面収録権限の不足。`$TERM_PROGRAM` と親プロセスから実行元アプリを特定し、システム設定 → プライバシーとセキュリティ → 画面収録 での許可をユーザーに依頼する（権限付与は Claude では行わない）

## 2-4. 元のウィンドウ配置に戻す

```bash
osascript -e 'tell application "Google Chrome" to set bounds of (first window whose id is <ウィンドウID>) to {<x1>, <y1>, <x2>, <y2>}'
```

`resize_window` は幅と高さしか扱えず位置を戻せないため、復元は `set bounds` で行います。2-2 で取り違えて動かした他のウィンドウがあればそれも戻し、2-1 のコマンドで確認してください。

# 3. 変換して保存先へ切り出す

PNG を Read すると元画像の寸法と表示倍率が返るので、それを使って掲載したい領域の座標を算出し、ffmpeg で切り出して JPEG に変換します。

```bash
ffmpeg -loglevel error -y -i "<PNG パス>" -vf "crop=<w>:<h>:<x>:<y>" -q:v 2 "<保存先パス>"
```

強調したい箇所がある場合は、`crop` の後ろに `drawbox` をカンマで繋いで赤枠を重ねます（座標は切り出し後の画像が基準。複数箇所はカンマで並べる）。

```bash
-vf "crop=<w>:<h>:<x>:<y>,drawbox=x=<x>:y=<y>:w=<w>:h=<h>:color=red@1.0:t=5"
```

- 保存先パスとファイル名の規約は呼び出し元が決める。入力で受け取ったパスをそのまま使う
- 赤枠は入力で指定された箇所だけに絞る
- ブラウザのタブバー・ブックマークバー・拡張機能アイコン・通知バナーは切り落とし、ページ本文の領域だけを残す（タブのタイトルに業務情報が写るため）
- 比較画像は左端・幅を揃え、同じ箇所を同じ大きさで切り出す
- **変換後の JPEG を Read で目視し、排除対象が写っていないか確認する**。テキストの grep 照合は画像を見ないため、画像の機密チェックはこの目視が最後の砦になる

# 4. 報告

以下を呼び出し元へ報告して完了とします。

- 切り出した JPEG のパス一覧
- 撮影した元 PNG（`${HOME}/Pictures/ScreenShot/` 配下）のパス一覧と、業務情報を含む画面全体が残っているため削除はユーザー判断である旨
- ウィンドウ配置を元に戻した旨（他のウィンドウを動かした場合はそれも含む）
