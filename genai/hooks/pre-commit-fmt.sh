#!/bin/bash
# PreToolUse hook: Run formatters on staged files before git commit
# Supports both Claude Code and Codex CLI

# fmt_* helpers are dispatched indirectly via process_ext "$fmt".
# shellcheck disable=SC2329

INPUT=$(cat)
COMMAND=$(jq -r '.tool_input.command // empty' <<<"$INPUT")

# Detect caller: `turn_id` is a Codex-specific field
if jq -e '.turn_id' <<<"$INPUT" >/dev/null 2>&1; then
	CALLER="Codex"
else
	CALLER="Claude Code"
fi

# Only run for git commit commands
if ! grep -qE '^git\s+commit' <<<"$COMMAND"; then
	exit 0
fi

STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)
if [[ -z "$STAGED_FILES" ]]; then
	exit 0
fi

FORMATTED_FILES=()

fmt_py() {
	xargs ruff check --fix <<<"$1" 2>/dev/null
	xargs ruff format <<<"$1" 2>/dev/null
}
fmt_js() { xargs biome check --fix <<<"$1" 2>/dev/null; }
fmt_tf() { xargs terraform fmt <<<"$1" 2>/dev/null; }
fmt_sh() { xargs shfmt -w <<<"$1" 2>/dev/null; }
fmt_md() { xargs markdownlint --fix --disable MD034 -- <<<"$1" 2>/dev/null; }

process_ext() {
	local pattern="$1" fmt="$2"
	local files
	files=$(grep -E "$pattern" <<<"$STAGED_FILES" || true)
	[[ -z "$files" ]] && return 0
	"$fmt" "$files"
	xargs git add <<<"$files"
	while IFS= read -r f; do FORMATTED_FILES+=("$f"); done <<<"$files"
}

process_ext '\.py$' fmt_py
process_ext '\.(ts|tsx|js|jsx|json)$' fmt_js
process_ext '\.tf$' fmt_tf
process_ext '\.sh$' fmt_sh
process_ext '\.md$' fmt_md

# Output result as JSON (both Claude Code and Codex accept `systemMessage`)
if [[ ${#FORMATTED_FILES[@]} -gt 0 ]]; then
	FILE_LIST=$(printf ', %s' "${FORMATTED_FILES[@]}")
	FILE_LIST=${FILE_LIST:2}
	printf '{"systemMessage":"Pre-commit (%s): formatted %d file(s): %s"}\n' \
		"${CALLER}" "${#FORMATTED_FILES[@]}" "${FILE_LIST}"
else
	printf '{"systemMessage":"Pre-commit (%s): no files matched formatting targets"}\n' \
		"${CALLER}"
fi

exit 0
