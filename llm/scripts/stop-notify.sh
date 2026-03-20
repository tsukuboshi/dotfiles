#!/bin/bash
# Claude Code 実行完了時にトースト通知を送信する

INPUT=$(cat)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')

# stop hook によるループを防止
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
	exit 0
fi

# サブエージェントの完了は通知しない
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // empty')
if [ -n "$AGENT_ID" ]; then
	exit 0
fi

# terminal-notifier が存在しない場合はスキップ
if ! command -v terminal-notifier &>/dev/null; then
	exit 0
fi

# 最後の応答から通知メッセージを生成
MESSAGE=$(echo "$INPUT" | jq -r '.last_assistant_message // empty' | head -c 200)
if [ -z "$MESSAGE" ]; then
	MESSAGE="タスクが完了しました"
fi

# 実行環境のターミナルアプリを判別
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
