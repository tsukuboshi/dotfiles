#!/bin/bash
# List Chrome windows as "<id> | <x1>,<y1>,<x2>,<y2> | <active tab URL>", one per line.
# Usage: chrome_windows.sh
set -euo pipefail

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
