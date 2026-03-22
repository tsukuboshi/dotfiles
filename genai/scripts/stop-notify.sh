#!/bin/bash
# Stop hook: Send toast notification when Claude Code finishes

INPUT=$(cat)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')

# Prevent loop caused by stop hook
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
	exit 0
fi

# Skip notification for sub-agent completion
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // empty')
if [ -n "$AGENT_ID" ]; then
	exit 0
fi

# Skip if terminal-notifier is not installed
if ! command -v terminal-notifier &>/dev/null; then
	exit 0
fi

# Generate notification message from last response
MESSAGE=$(echo "$INPUT" | jq -r '.last_assistant_message // empty' | head -c 200)
if [ -z "$MESSAGE" ]; then
	MESSAGE="Task completed"
fi

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
if [ -n "$BUNDLE_ID" ]; then
	ACTIVATE_OPTS=(-activate "$BUNDLE_ID")
fi

terminal-notifier \
	-title "Claude Code" \
	-message "$MESSAGE" \
	-group "claude-code" \
	"${ACTIVATE_OPTS[@]}"

exit 0
