#!/bin/bash
# PreToolUse hook: block commands that access secrets or exfiltrate data

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [[ -z "$COMMAND" ]]; then
	exit 0
fi

# Sensitive file access patterns
SENSITIVE_PATHS=(
	'\.ssh/id_'
	'\.ssh/.*key'
	'\.aws/credentials'
	'\.gnupg/'
	'\.config/gh/'
	'\.env'
	'secrets/'
	'credentials\.json'
)

for pattern in "${SENSITIVE_PATHS[@]}"; do
	if echo "$COMMAND" | grep -qE "$pattern"; then
		echo "Blocked: command accesses sensitive path matching '${pattern}'" >&2
		exit 2
	fi
done

# Data exfiltration patterns
EXFIL_PATTERNS=(
	'\bnc\b.*[0-9]+\.[0-9]+'
	'\bncat\b'
	'\bsocat\b.*TCP'
	'\bscp\b'
	'\bsftp\b'
	'\brsync\b.*:'
	'\bbase64\b.*\|'
)

for pattern in "${EXFIL_PATTERNS[@]}"; do
	if echo "$COMMAND" | grep -qE "$pattern"; then
		echo "Blocked: command matches exfiltration pattern '${pattern}'" >&2
		exit 2
	fi
done

# Shell config modification
SHELL_CONFIGS=(
	'\.bashrc'
	'\.zshrc'
	'\.bash_profile'
	'\.zprofile'
	'\.profile'
)

for pattern in "${SHELL_CONFIGS[@]}"; do
	if echo "$COMMAND" | grep -qE "(>|>>|tee|mv|cp).*${pattern}"; then
		echo "Blocked: command modifies shell config matching '${pattern}'" >&2
		exit 2
	fi
done

exit 0
