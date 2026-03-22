#!/bin/bash
# PreToolUse hook: Run formatters on staged files before git commit

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only run for git commit commands
if ! echo "$COMMAND" | grep -qE '^git\s+commit'; then
	exit 0
fi

# Get staged files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

if [[ -z "$STAGED_FILES" ]]; then
	exit 0
fi

REFORMATTED=false

# Python files
PY_FILES=$(echo "$STAGED_FILES" | grep '\.py$' || true)
if [[ -n "$PY_FILES" ]]; then
	echo "$PY_FILES" | xargs ruff check --fix 2>/dev/null
	echo "$PY_FILES" | xargs ruff format 2>/dev/null
	echo "$PY_FILES" | xargs git add
	REFORMATTED=true
fi

# TypeScript/JavaScript files
JS_FILES=$(echo "$STAGED_FILES" | grep -E '\.(ts|tsx|js|jsx)$' || true)
if [[ -n "$JS_FILES" ]]; then
	echo "$JS_FILES" | xargs biome check --fix 2>/dev/null
	echo "$JS_FILES" | xargs git add
	REFORMATTED=true
fi

# Terraform files
TF_FILES=$(echo "$STAGED_FILES" | grep '\.tf$' || true)
if [[ -n "$TF_FILES" ]]; then
	echo "$TF_FILES" | xargs terraform fmt 2>/dev/null
	echo "$TF_FILES" | xargs git add
	REFORMATTED=true
fi

# Shell files
SH_FILES=$(echo "$STAGED_FILES" | grep '\.sh$' || true)
if [[ -n "$SH_FILES" ]]; then
	echo "$SH_FILES" | xargs shfmt -w 2>/dev/null
	echo "$SH_FILES" | xargs git add
	REFORMATTED=true
fi

# Markdown files
MD_FILES=$(echo "$STAGED_FILES" | grep '\.md$' || true)
if [[ -n "$MD_FILES" ]]; then
	echo "$MD_FILES" | xargs markdownlint --fix --disable MD034 -- 2>/dev/null
	echo "$MD_FILES" | xargs git add
	REFORMATTED=true
fi

if [[ "$REFORMATTED" == "true" ]]; then
	echo "Pre-commit: formatted staged files"
fi

exit 0
