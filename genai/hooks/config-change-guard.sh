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
	exit 0
fi

# Block bypassPermissions mode. Sandbox keys stay unchecked on purpose: this
# repository ships sandbox disabled, so guarding them would block every edit to
# its own settings.json.
if [[ -f "$FILE_PATH" ]] &&
	jq -e '.permissions.defaultMode == "bypassPermissions"' "$FILE_PATH" >/dev/null 2>&1; then
	printf '{"decision":"block","reason":"bypassPermissions is not allowed for security reasons"}\n'
	exit 0
fi

exit 0
