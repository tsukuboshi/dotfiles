#!/bin/bash
# ConfigChange hook: block dangerous configuration changes

INPUT=$(cat)

# Extract source
SOURCE=$(echo "$INPUT" | jq -r '.source // "unknown"')

# policy_settings changes cannot be blocked per official docs
if [[ "$SOURCE" == "policy_settings" ]]; then
	printf '{"decision":"allow"}\n'
	exit 0
fi

# Block dangerous configuration changes
FILE_PATH=$(echo "$INPUT" | jq -r '.file_path // "unknown"')
if [[ -f "$FILE_PATH" ]]; then
	VIOLATION=$(jq -r '
		if .defaultMode == "bypassPermissions" then "bypassPermissions"
		elif .sandbox.allowUnsandboxedCommands == true then "allowUnsandboxedCommands"
		elif .sandbox.enabled == false then "sandbox disabled"
		else empty
		end
	' "$FILE_PATH" 2>/dev/null)

	if [[ -n "$VIOLATION" ]]; then
		printf '{"decision":"block","reason":"%s is not allowed for security reasons"}\n' \
			"${VIOLATION}"
		exit 2
	fi
fi

printf '{"decision":"allow"}\n'
exit 0
