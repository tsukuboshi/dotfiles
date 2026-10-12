#!/bin/sh
# UserPromptSubmit hook: Rename the herdr tab to the head of the submitted prompt
# Based on https://tech.anycloud.co.jp/articles/herdr-claude-code-tab-title/
set -u

# Save the hook input first because the heredoc below takes over stdin
hook_input_file="$(mktemp)" || exit 0
trap 'rm -f "$hook_input_file"' EXIT
cat >"$hook_input_file" 2>/dev/null || true

# Run only inside a herdr pane
[ "${HERDR_ENV:-}" = "1" ] || exit 0
command -v herdr >/dev/null 2>&1 || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

# Keep stdout empty: UserPromptSubmit stdout is injected into the model context
HOOK_INPUT_FILE="$hook_input_file" python3 - <<'PY' >/dev/null 2>&1
import json, os, subprocess, sys

with open(os.environ["HOOK_INPUT_FILE"], encoding="utf-8") as fh:
    d = json.load(fh)
if d.get("agent_id"):  # Ignore subagent events
    sys.exit(0)

prompt = " ".join(str(d.get("prompt") or "").split())
if not prompt:
    sys.exit(0)
title = prompt[:19] + "…" if len(prompt) > 20 else prompt
session_id = str(d.get("session_id") or "")

out = subprocess.run(["herdr", "api", "snapshot"],
                     capture_output=True, text=True, timeout=3).stdout
snap = json.loads(out)["result"]["snapshot"]
agents = snap.get("agents") or []

# (1) The tab whose agent reported this session ID to herdr
target = next((a["tab_id"] for a in agents
               if (a.get("agent_session") or {}).get("value") == session_id), None)

# (2) Otherwise, the focused pane's tab if it runs claude without a reported session
if target is None:
    fp = snap.get("focused_pane_id")
    target = next((a["tab_id"] for a in agents
                   if a.get("pane_id") == fp and a.get("agent") == "claude"
                   and not (a.get("agent_session") or {}).get("value")), None)

# (3) Do nothing when neither matches
if target:
    subprocess.run(["herdr", "tab", "rename", target, title],
                   capture_output=True, timeout=3)
PY
exit 0
