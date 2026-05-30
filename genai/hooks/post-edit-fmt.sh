#!/bin/bash
# PostToolUse hook: Run linter/formatter when supported files are edited
# Supports both Claude Code (Edit/Write/MultiEdit) and Codex (apply_patch)

INPUT=$(cat)
TOOL_NAME=$(jq -r '.tool_name // empty' <<<"$INPUT")
TOOL_COMMAND=$(jq -r '.tool_input.command // empty' <<<"$INPUT")

format_file() {
	local file_path="$1"

	[[ -z "$file_path" || ! -f "$file_path" ]] && return 0

	case "$file_path" in
	*.tf)
		terraform fmt "$file_path"
		;;
	*.py)
		ruff check --fix "$file_path"
		ruff format "$file_path"
		;;
	*.ts | *.tsx | *.js | *.jsx | *.json)
		biome check --fix "$file_path"
		;;
	*.md)
		markdownlint --fix --disable MD034 -- "$file_path"
		;;
	*.sh)
		shfmt -w "$file_path"
		shellcheck "$file_path"
		;;
	esac
}

if [[ "$TOOL_NAME" == "apply_patch" ]]; then
	while IFS= read -r file_path; do
		format_file "$file_path"
	done < <(
		awk '
			/^\*\*\* (Add|Update) File: / { sub(/^\*\*\* (Add|Update) File: /, ""); print }
			/^\*\*\* Move to: / { sub(/^\*\*\* Move to: /, ""); print }
		' <<<"$TOOL_COMMAND" | sort -u
	)
else
	FILE_PATH=$(jq -r '.tool_input.file_path // empty' <<<"$INPUT")
	format_file "$FILE_PATH"
fi

exit 0
