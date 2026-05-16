#!/bin/bash
# ConfigChange hook: block dangerous configuration changes

INPUT=$(cat)

# Extract source and file_path in one jq call
IFS=$'\t' read -r SOURCE FILE_PATH < <(
	jq -r '[
    (.source // "unknown"),
    (.file_path // "unknown")
  ] | @tsv' <<<"$INPUT"
)

# policy_settings changes cannot be blocked per official docs
if [[ "$SOURCE" == "policy_settings" ]]; then
	printf '{"decision":"allow"}\n'
	exit 0
fi

# Block dangerous configuration changes
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
