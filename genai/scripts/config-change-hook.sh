#!/bin/bash
# ConfigChange hook: audit settings changes and block dangerous configurations

INPUT=$(cat)
TIMESTAMP=$(date -Iseconds)
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LOG_DIR="${REPO_ROOT}/.claude"
[[ -d "${LOG_DIR}" ]] || mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/audit-$(date +%Y%m).log"

# Extract source and file_path in a single jq call
eval "$(echo "$INPUT" | jq -r '@sh "SOURCE=\(.source // "unknown") FILE_PATH=\(.file_path // "unknown")"')"

# Audit log with source and file path
echo "[${TIMESTAMP}] Config changed: source=${SOURCE} file=${FILE_PATH}" >>"${LOG_FILE}"

# policy_settings changes cannot be blocked per official docs
if [[ "$SOURCE" == "policy_settings" ]]; then
	echo "[${TIMESTAMP}] Policy settings change (cannot block): ${FILE_PATH}" >>"${LOG_FILE}"
	printf '{"decision":"allow"}\n'
	exit 0
fi

# Block dangerous configuration changes in a single jq call
if [[ -f "$FILE_PATH" ]]; then
	VIOLATION=$(jq -r '
		if .defaultMode == "bypassPermissions" then "bypassPermissions"
		elif .sandbox.allowUnsandboxedCommands == true then "allowUnsandboxedCommands"
		elif .sandbox.enabled == false then "sandbox disabled"
		else empty
		end
	' "$FILE_PATH" 2>/dev/null)

	if [[ -n "$VIOLATION" ]]; then
		echo "[${TIMESTAMP}] BLOCKED: ${VIOLATION} detected in ${FILE_PATH}" >>"${LOG_FILE}"
		printf '{"decision":"block","reason":"%s is not allowed for security reasons"}\n' \
			"${VIOLATION}"
		exit 2
	fi
fi

printf '{"decision":"allow"}\n'
exit 0
