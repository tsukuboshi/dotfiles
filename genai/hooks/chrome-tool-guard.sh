#!/bin/bash
# PreToolUse hook: narrow Claude in Chrome tools to the operations listed below
#   computer:        actions that do not change the page only: scroll, scroll_to, screenshot,
#                    zoom, hover and wait (clicks, typing, key presses and drags stay blocked)
#   javascript_tool: a single page zoom assignment only, e.g. document.body.style.zoom = '80%'
#                    (25-100% or 0.25-1). Any other string in tool_input, besides lowercase
#                    identifiers such as the action name, is denied.
# Fails closed: any other tool name, action or script, and unreadable input, is denied.

INPUT=$(cat)
TOOL_NAME=$(jq -r '.tool_name // empty' <<<"$INPUT" 2>/dev/null)

DECISION="deny"
REASON="This operation is not allowed for ${TOOL_NAME:-unknown}. Ask the user to perform it."

guard_computer() {
	local action
	action=$(jq -r '.tool_input.action // empty' <<<"$INPUT" 2>/dev/null)
	case "$action" in
	scroll | scroll_to | screenshot | zoom | hover | wait)
		DECISION="allow"
		REASON="Non-mutating action is allowed"
		;;
	*)
		REASON="Only scroll, scroll_to, screenshot, zoom, hover and wait are allowed for ${TOOL_NAME} (got: ${action:-unknown}). Ask the user to perform this action."
		;;
	esac
}

guard_javascript() {
	local zoom_re="^document\.body\.style\.zoom[[:space:]]*=[[:space:]]*(['\"])((2[5-9]|[3-9][0-9]|100)%|0?\.(2[5-9]|[3-9][0-9]?)|1(\.0+)?)['\"][[:space:]]*;?$"
	local ident_re='^[a-z_]+$'
	local strings s zoom_found=0 other_found=0

	REASON="Only a page zoom assignment (document.body.style.zoom = '25%'-'100%') is allowed for ${TOOL_NAME}. Ask the user to perform this action."
	strings=$(jq -r '.tool_input | [.. | strings] | .[]' <<<"$INPUT" 2>/dev/null) || return
	while IFS= read -r s; do
		[[ -z "$s" ]] && continue
		if [[ "$s" =~ $zoom_re ]]; then
			zoom_found=1
		elif [[ ! "$s" =~ $ident_re ]]; then
			other_found=1
		fi
	done <<<"$strings"
	if [[ $zoom_found -eq 1 && $other_found -eq 0 ]]; then
		DECISION="allow"
		REASON="Page zoom change is allowed"
	fi
}

case "$TOOL_NAME" in
mcp__claude-in-chrome__computer) guard_computer ;;
mcp__claude-in-chrome__javascript_tool) guard_javascript ;;
esac

jq -n --arg d "$DECISION" --arg r "$REASON" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: $d,
    permissionDecisionReason: $r
  }
}'
