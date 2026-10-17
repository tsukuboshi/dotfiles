#!/bin/bash
# Put a Chrome window back at the given bounds, then list every window to confirm.
# Usage: chrome_restore.sh <window-id> <x1> <y1> <x2> <y2>
set -euo pipefail

if [[ $# -ne 5 ]]; then
	echo "usage: $0 <window-id> <x1> <y1> <x2> <y2>" >&2
	exit 64
fi
for v in "$@"; do
	if [[ ! "$v" =~ ^-?[0-9]+$ ]]; then
		echo "not an integer: ${v}" >&2
		exit 64
	fi
done

osascript - "$@" <<'AS'
on run argv
  set wid to (item 1 of argv) as integer
  set nb to {(item 2 of argv) as integer, (item 3 of argv) as integer, (item 4 of argv) as integer, (item 5 of argv) as integer}
  tell application "Google Chrome" to set bounds of (first window whose id is wid) to nb
end run
AS
bash "$(dirname "$0")/chrome_windows.sh"
