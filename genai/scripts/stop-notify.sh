#!/bin/bash
# Stop hook: Send toast notification when Claude Code finishes

INPUT=$(cat)

# Extract control flags in a single jq call (tab-separated)
IFS=$'\t' read -r STOP_HOOK_ACTIVE AGENT_ID < <(
	jq -r '[
    (.stop_hook_active // false | tostring),
    (.agent_id // "")
  ] | @tsv' <<<"$INPUT"
)

# Prevent loop caused by stop hook
[[ "$STOP_HOOK_ACTIVE" == "true" ]] && exit 0

# Skip notification for sub-agent completion
[[ -n "$AGENT_ID" ]] && exit 0

# Skip if terminal-notifier is not installed
command -v terminal-notifier &>/dev/null || exit 0

# Message is read separately to preserve byte-level truncation (head -c)
MESSAGE=$(jq -r '.last_assistant_message // empty' <<<"$INPUT" | head -c 200)
[[ -z "$MESSAGE" ]] && MESSAGE="Task completed"

# Detect terminal application
case "$TERM_PROGRAM" in
vscode) BUNDLE_ID="com.microsoft.VSCode" ;;
iTerm.app) BUNDLE_ID="com.googlecode.iterm2" ;;
Apple_Terminal) BUNDLE_ID="com.apple.Terminal" ;;
ghostty) BUNDLE_ID="com.mitchellh.ghostty" ;;
WezTerm) BUNDLE_ID="com.github.wez.wezterm" ;;
*) BUNDLE_ID="" ;;
esac

ACTIVATE_OPTS=()
[[ -n "$BUNDLE_ID" ]] && ACTIVATE_OPTS=(-activate "$BUNDLE_ID")

terminal-notifier \
	-title "Claude Code" \
	-message "$MESSAGE" \
	-group "claude-code" \
	"${ACTIVATE_OPTS[@]}"

exit 0
