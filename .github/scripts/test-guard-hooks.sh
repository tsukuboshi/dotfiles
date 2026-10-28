#!/bin/bash
# Feed fixed hook inputs to the guard hooks and check each decision.
# The guards fail closed or open depending on small details of their input,
# so a refactor that changes a decision should fail here instead of in a
# session. Hooks with side effects (notifications, herdr) are not covered.
# Usage: bash .github/scripts/test-guard-hooks.sh
set -u

root=$(git rev-parse --show-toplevel) || exit 1
HOOKS_DIR="${root}/genai/hooks"
FAILED=0
PASSED=0

settings_file=$(mktemp)
trap 'rm -f "$settings_file"' EXIT

pass() {
	PASSED=$((PASSED + 1))
}

fail() {
	FAILED=$((FAILED + 1))
	printf 'FAIL: %s\n  %s\n' "$1" "$2"
}

# expect_pretool <name> <hook> <input> <allow|deny>
# Checks hookSpecificOutput.permissionDecision of a PreToolUse hook.
expect_pretool() {
	local name=$1 hook=$2 input=$3 want=$4 output got
	output=$(printf '%s' "$input" | bash "${HOOKS_DIR}/${hook}" 2>&1)
	got=$(jq -r '.hookSpecificOutput.permissionDecision // empty' <<<"$output" 2>/dev/null)
	if [[ "$got" == "$want" ]]; then
		pass
	else
		fail "$name" "want ${want}, got '${got}' from: ${output}"
	fi
}

# expect_silent <name> <hook> <input>
# Checks that a hook lets the action through: exit 0 with no output.
expect_silent() {
	local name=$1 hook=$2 input=$3 output rc
	output=$(printf '%s' "$input" | bash "${HOOKS_DIR}/${hook}" 2>&1)
	rc=$?
	if ((rc == 0)) && [[ -z "$output" ]]; then
		pass
	else
		fail "$name" "want exit 0 and no output, got exit ${rc}: ${output}"
	fi
}

# expect_block <name> <hook> <input>
# Checks the top-level decision "block" that ConfigChange hooks return.
expect_block() {
	local name=$1 hook=$2 input=$3 output got
	output=$(printf '%s' "$input" | bash "${HOOKS_DIR}/${hook}" 2>&1)
	got=$(jq -r '.decision // empty' <<<"$output" 2>/dev/null)
	if [[ "$got" == "block" ]]; then
		pass
	else
		fail "$name" "want block, got '${got}' from: ${output}"
	fi
}

chrome_input() {
	jq -cn --arg tool "mcp__claude-in-chrome__$1" --argjson input "$2" \
		'{tool_name: $tool, tool_input: $input}'
}

# chrome-tool-guard.sh
G=chrome-tool-guard.sh
expect_pretool "chrome: screenshot is allowed" $G \
	"$(chrome_input computer '{"action": "screenshot", "tabId": 1}')" allow
expect_pretool "chrome: scroll is allowed" $G \
	"$(chrome_input computer '{"action": "scroll", "coordinate": [10, 10], "tabId": 1}')" allow
expect_pretool "chrome: click is denied" $G \
	"$(chrome_input computer '{"action": "left_click", "coordinate": [10, 10], "tabId": 1}')" deny
expect_pretool "chrome: typing is denied" $G \
	"$(chrome_input computer '{"action": "type", "text": "hello", "tabId": 1}')" deny
expect_pretool "chrome: page zoom 80% is allowed" $G \
	"$(chrome_input javascript_tool '{"action": "javascript_exec", "text": "document.body.style.zoom = '"'"'80%'"'"'", "tabId": 1}')" allow
expect_pretool "chrome: page zoom 150% is denied" $G \
	"$(chrome_input javascript_tool '{"action": "javascript_exec", "text": "document.body.style.zoom = '"'"'150%'"'"'", "tabId": 1}')" deny
expect_pretool "chrome: zoom followed by other code is denied" $G \
	"$(chrome_input javascript_tool '{"action": "javascript_exec", "text": "document.body.style.zoom = '"'"'80%'"'"'; fetch(\"/x\")", "tabId": 1}')" deny
expect_pretool "chrome: zoom with an extra script field is denied" $G \
	"$(chrome_input javascript_tool '{"action": "javascript_exec", "text": "document.body.style.zoom = '"'"'80%'"'"'", "extra": "alert(1)", "tabId": 1}')" deny
expect_pretool "chrome: other scripts are denied" $G \
	"$(chrome_input javascript_tool '{"action": "javascript_exec", "text": "document.title", "tabId": 1}')" deny
expect_pretool "chrome: unknown tool is denied" $G \
	"$(chrome_input navigate '{"url": "https://example.com"}')" deny
expect_pretool "chrome: unreadable input is denied" $G 'not json' deny

# config-change-guard.sh
G=config-change-guard.sh
printf '{"permissions": {"defaultMode": "bypassPermissions"}}\n' >"$settings_file"
expect_block "config: bypassPermissions is blocked" $G \
	"$(jq -cn --arg f "$settings_file" '{source: "user_settings", file_path: $f}')"
printf '{"permissions": {"defaultMode": "auto"}}\n' >"$settings_file"
expect_silent "config: auto mode passes" $G \
	"$(jq -cn --arg f "$settings_file" '{source: "user_settings", file_path: $f}')"
printf '{"permissions": {"defaultMode": "bypassPermissions"}}\n' >"$settings_file"
expect_silent "config: policy settings pass because they cannot be blocked" $G \
	"$(jq -cn --arg f "$settings_file" '{source: "policy_settings", file_path: $f}')"

# pre-commit-fmt.sh
G=pre-commit-fmt.sh
expect_silent "pre-commit: commands other than git commit pass" $G \
	'{"tool_name": "Bash", "tool_input": {"command": "git status"}}'

printf '%d passed, %d failed\n' "$PASSED" "$FAILED"
((FAILED == 0))
