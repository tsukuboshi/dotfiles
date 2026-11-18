#!/bin/bash
# Render a generated page in headless Chrome and report as JSON whether every
# Mermaid figure was drawn, along with a full-page screenshot to look at.
# A bash rewrite of verify_page.py from keitakn/engineering-skills (MIT):
# https://github.com/keitakn/engineering-skills/blob/main/.claude/skills/explain-visually/scripts/verify_page.py
# Usage: verify_page.sh <html> [--width <px>] [--wait <ms>] [--timeout <s>]
#   --width:   the viewport width (default: 1250).
#   --wait:    the virtual time in ms to let the page draw (default: 25000).
#   --timeout: the seconds before each Chrome run is stopped (default: 40).
#   VISUALIZE_DIFF_CHROME: the Chrome binary, for tests to swap in a stub.
# Chrome keeps its profile in ${TMPDIR:-/tmp}/visualize-diff-chrome-profile
# across runs, so cleaning up never has to delete a directory tree.
set -euo pipefail

chrome=${VISUALIZE_DIFF_CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}
tmp=${TMPDIR:-/tmp}
tmp=${tmp%/}
profile="${tmp}/visualize-diff-chrome-profile"
width=1250
wait_ms=25000
timeout=40

usage() {
	echo "usage: $0 <html> [--width <px>] [--wait <ms>] [--timeout <s>]" >&2
	exit 64
}

# error <message> — prints the JSON for a run that could not check the page.
error() {
	jq -n --arg error "$1" '{ok: false, error: $error}'
	exit 1
}

[[ $# -ge 1 ]] || usage
page=$1
shift
while [[ $# -gt 0 ]]; do
	[[ $# -ge 2 && "$2" =~ ^[0-9]+$ ]] || usage
	case $1 in
	--width) width=$2 ;;
	--wait) wait_ms=$2 ;;
	--timeout) timeout=$2 ;;
	*) usage ;;
	esac
	shift 2
done
[[ -f "$page" ]] || error "ファイルが見つかりません: ${page}"
[[ -x "$chrome" ]] || error "Google Chrome が見つかりません: ${chrome}"

html="$(cd "$(dirname "$page")" && pwd)/$(basename "$page")"
# Encoded so a # or ? in the file name is not read as a fragment or a query.
path=${html//%/%25}
path=${path//\#/%23}
path=${path//\?/%3F}
url="file://${path// /%20}"

# Two Chrome runs on one profile hand off to each other and come back empty,
# so runs take turns through a lock directory holding the owner's pid. A lock
# whose owner has exited is taken over.
lock="${profile}.lock"
locked=false
for ((i = 0; i < (timeout * 2 + 5) * 10; i++)); do
	if mkdir "$lock" 2>/dev/null; then
		echo "$$" >"${lock}/pid"
		locked=true
		break
	fi
	owner=$(cat "${lock}/pid" 2>/dev/null || true)
	if [[ -n "$owner" ]] && ! kill -0 "$owner" 2>/dev/null; then
		rm -f "${lock}/pid"
		rmdir "$lock" 2>/dev/null || true
		continue
	fi
	sleep 0.1
done
[[ $locked == true ]] || error "Chrome のプロファイルが別の実行で使用中: ${lock}（pid $(cat "${lock}/pid" 2>/dev/null)）"

# A template, since mktemp -d alone ignores TMPDIR on macOS.
work=$(mktemp -d "${tmp}/visualize-diff.XXXXXX")
trap 'rm -f "${work}/dom.html" "${work}/shot.png" "${lock}/pid"; rmdir "$work" "$lock"' EXIT

# run_chrome <out-file> <chrome args...>
# Headless Chrome may keep running after it has written its output, and its
# helper processes outlive it, so the run is started in its own process group
# and the whole group is stopped once Chrome exits or the timeout passes.
run_chrome() {
	local out=$1 pid i
	shift
	set -m
	"$chrome" --headless=new --disable-gpu --disable-crash-reporter --no-first-run \
		"--user-data-dir=${profile}" --hide-scrollbars "$@" "$url" >"$out" 2>/dev/null &
	pid=$!
	set +m
	for ((i = 0; i < timeout * 10; i++)); do
		kill -0 "$pid" 2>/dev/null || break
		sleep 0.1
	done
	kill -KILL -- "-${pid}" 2>/dev/null || true
	wait "$pid" 2>/dev/null || true
}

# count <extended regex> <text> — the number of matches in the text.
count() {
	{ grep -oE "$1" <<<"$2" || true; } | wc -l | tr -d ' '
}

run_chrome "${work}/dom.html" "--window-size=${width},1200" "--virtual-time-budget=${wait_ms}" --dump-dom
# Joined into one line so a pattern can span the line breaks in the DOM.
dom=$(tr '\n' ' ' <"${work}/dom.html")
[[ "$dom" == *"<html"* ]] || error "Chrome から DOM を取得できなかった。--timeout 秒以内に描画が終わらなかったか、Chrome が起動しなかった"

# The DOM escapes < in text, so a pattern that starts with < matches only
# tags, never a diff quoted on the page. The flags are read from the body tag
# and the title from the first title tag, which is the one in head.
# A figure counts as drawn only when its SVG sits inside it, since Mermaid
# leaves the error SVG of a figure it could not parse at the end of the body.
figure_re='<[A-Za-z]+[^>]*[[:space:]]class="([^"]* )?mermaid( [^"]*)?"'
sources=$(count "$figure_re" "$dom")
rendered=$(count "${figure_re}[^>]*>[[:space:]]*<svg id=\"fig-[0-9]+\"" "$dom")
body_re='<body[^>]*>'
title_re='<title>([^<]*)</title>'
height_re='data-page-height="([0-9]+)"'
body_tag=
title=
page_height=
[[ "$dom" =~ $body_re ]] && body_tag=${BASH_REMATCH[0]}
[[ "$dom" =~ $title_re ]] && title=${BASH_REMATCH[1]}
[[ "$body_tag" =~ $height_re ]] && page_height=${BASH_REMATCH[1]}
ready=false
[[ "$body_tag" == *'data-mermaid-ready="1"'* ]] && ready=true

warnings=()
if ((sources > 0)) && [[ $ready == false ]]; then
	warnings+=("Mermaid の描画完了フラグが立っていない。CDN に到達できていない。Bash のサンドボックス内では外部ホストに到達できないため、サンドボックス無しで再実行する")
fi
if ((sources > 0 && rendered != sources)); then
	warnings+=("Mermaid の図が ${sources} 個あるのに描画されたのは ${rendered} 個。記法エラーか id の衝突が疑われる。描画されずに記法のまま残った図を直す")
fi
if [[ -z "$page_height" ]]; then
	# Chrome's --screenshot only covers the window, so the page height is the
	# window height to use; this one is a guess that may cut off the end.
	page_height=12000
	warnings+=("ページ高さを取得できなかった。テンプレートの高さ出力 script が消えている可能性がある。既定の ${page_height}px で撮影したため、末尾が切れていないかスクリーンショットで目視する")
fi

shot="${html%.html}-shot.png"
# Taken into the work directory and moved over the page's shot only once it
# exists, so a shot left by an earlier run is never reported as this one.
run_chrome /dev/null "--virtual-time-budget=${wait_ms}" "--window-size=${width},$((page_height + 40))" "--screenshot=${work}/shot.png"
[[ -f "${work}/shot.png" ]] || error "スクリーンショットを生成できなかった: ${shot}"
mv -f "${work}/shot.png" "$shot"

jq -n \
	--arg html "$html" --arg title "$title" --argjson pageHeight "$page_height" \
	--argjson sources "$sources" --argjson rendered "$rendered" --argjson ready "$ready" \
	--arg screenshot "$shot" \
	'$ARGS.positional as $w
	 | {ok: ($w == []), html: $html, title: $title, pageHeight: $pageHeight,
	    mermaidSources: $sources, mermaidRendered: $rendered, mermaidReady: $ready,
	    screenshot: $screenshot, warnings: $w}' \
	--args ${warnings[@]+"${warnings[@]}"}
