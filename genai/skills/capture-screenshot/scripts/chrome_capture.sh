#!/bin/bash
# Bring a Chrome window to the front and capture it with screencapture.
# Usage: chrome_capture.sh <window-id> [<png-path>] [<width> <height>]
#   png-path: defaults to ~/Pictures/ScreenShot/スクリーンショット <JST time>.png,
#             the name macOS gives its own screenshots. Pass "" to keep the
#             default while giving a size.
#   width, height (pt): capture only when the window has this size, which
#             catches resize_window having resized a different window.
# Prints the window bounds, the PNG path and size, and its pixels per point.
set -euo pipefail

usage() {
	echo "usage: $0 <window-id> [<png-path>] [<width> <height>]" >&2
	exit 64
}

[[ $# -eq 1 || $# -eq 2 || $# -eq 4 ]] || usage
id=$1
[[ "$id" =~ ^[0-9]+$ ]] || usage
png=${2:-}
[[ -n "$png" ]] || png="${HOME}/Pictures/ScreenShot/スクリーンショット $(TZ=Asia/Tokyo date '+%Y-%m-%d %H.%M.%S').png"
want_w=${3:-}
want_h=${4:-}
if [[ -n "$want_w" ]]; then
	[[ "$want_w" =~ ^[0-9]+$ && "$want_h" =~ ^[0-9]+$ ]] || usage
fi

# Wait until Chrome is frontmost with the window on top instead of sleeping a
# fixed time; the short delay after that lets the raised window finish drawing.
state=$(
	osascript - "$id" <<'AS'
on run argv
  set wid to (item 1 of argv) as integer
  tell application "Google Chrome"
    activate
    set w to first window whose id is wid
    set index of w to 1
    set polls to 0
    set front to false
    repeat 40 times
      if frontmost and (id of window 1) is wid then
        set front to true
        exit repeat
      end if
      delay 0.05
      set polls to polls + 1
    end repeat
    delay 0.3
    set b to bounds of w
  end tell
  return (item 1 of b as text) & "," & (item 2 of b) & "," & (item 3 of b) & "," & (item 4 of b) & "," & front & "," & (polls * 50)
end run
AS
)
IFS=, read -r x1 y1 x2 y2 front waited_ms <<<"$state"
w=$((x2 - x1))
h=$((y2 - y1))
echo "window ${id}: bounds ${x1},${y1},${x2},${y2} (${w}x${h} pt), waited ${waited_ms} ms for the front"
if [[ "$front" != "true" ]]; then
	echo "warning: Chrome did not come to the front; check the PNG for windows on top of it" >&2
fi

if [[ -n "$want_w" ]] && ((w != want_w || h != want_h)); then
	echo "window ${id} is ${w}x${h} pt, not ${want_w}x${want_h}; nothing captured" >&2
	bash "$(dirname "$0")/chrome_windows.sh" >&2
	exit 3
fi

mkdir -p "$(dirname "$png")"
screencapture -x -R "${x1},${y1},${w},${h}" "$png"
read -r pw ph < <(sips -g pixelWidth -g pixelHeight "$png" | awk '/pixel(Width|Height)/ { printf "%s ", $2 }')
echo "png: ${png} (${pw}x${ph} px, $((pw / w)) px/pt)"
