#!/bin/bash
# Claude in Chrome guard. Registered for two events:
#
# PreToolUse: narrow Claude in Chrome tools to the operations listed below
#   computer:        actions that do not change the page: scroll, scroll_to, screenshot,
#                    zoom, hover and wait. Clicks, typing, key presses and drags are allowed
#                    only on a tab whose last recorded URL is on a loopback host
#                    (127.0.0.1, localhost, *.localhost, [::1]), for testing local apps.
#   javascript_tool: a single page zoom assignment only, e.g. document.body.style.zoom = '80%'
#                    (25-100% or 0.25-1). Any other string in tool_input, besides lowercase
#                    identifiers such as the action name, is denied.
# Fails closed: any other tool name, action or script, and unreadable input, is denied.
#
# PostToolUse: record each tab's current URL. Every Claude in Chrome result
# carries a tab context listing `tabId <id>: "<title>" ("<url>")`; the last URL
# seen for a tab is the one PreToolUse checks. A click that leaves the loopback
# host is recorded by its own result, so the next action on that tab is denied.

INPUT=$(cat)
EVENT=$(jq -r '.hook_event_name // empty' <<<"$INPUT" 2>/dev/null)
TOOL_NAME=$(jq -r '.tool_name // empty' <<<"$INPUT" 2>/dev/null)
SESSION_ID=$(jq -r '.session_id // empty' <<<"$INPUT" 2>/dev/null | tr -cd 'A-Za-z0-9-')

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/claude-chrome-guard"
TAB_FILE="$STATE_DIR/tabs-${SESSION_ID:-unknown}.tsv"

LOOPBACK_URL_RE='^https?://(127\.0\.0\.1|localhost|[a-z0-9-]+\.localhost|\[::1\])(:[0-9]+)?(/|$)'
TAB_LINE_RE='tabId ([0-9]+): .*\("([^"]*)"\)[[:space:]]*$'

record_tab_urls() {
	local text line
	text=$(jq -r '.tool_response | [.. | strings] | .[]' <<<"$INPUT" 2>/dev/null) || return 0
	mkdir -p "$STATE_DIR" && chmod 700 "$STATE_DIR" || return 0
	while IFS= read -r line; do
		if [[ "$line" =~ $TAB_LINE_RE ]]; then
			printf '%s\t%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" >>"$TAB_FILE"
		fi
	done <<<"$text"
}

# Prints the last URL recorded for a tab, or nothing.
last_url_of_tab() {
	local tab_id=$1
	[[ -f "$TAB_FILE" ]] || return 0
	awk -F'\t' -v id="$tab_id" '$1 == id { url = $2 } END { if (url != "") print url }' "$TAB_FILE"
}

if [[ "$EVENT" == "PostToolUse" ]]; then
	record_tab_urls
	exit 0
fi

DECISION="deny"
REASON="This operation is not allowed for ${TOOL_NAME:-unknown}. Ask the user to perform it."

guard_computer() {
	local action tab_id url
	action=$(jq -r '.tool_input.action // empty' <<<"$INPUT" 2>/dev/null)
	case "$action" in
	scroll | scroll_to | screenshot | zoom | hover | wait)
		DECISION="allow"
		REASON="Non-mutating action is allowed"
		;;
	left_click | right_click | double_click | triple_click | type | key | left_click_drag)
		tab_id=$(jq -r '.tool_input.tabId // empty' <<<"$INPUT" 2>/dev/null)
		url=$(last_url_of_tab "$tab_id")
		if [[ "$tab_id" =~ ^[0-9]+$ && "$url" =~ $LOOPBACK_URL_RE ]]; then
			DECISION="allow"
			REASON="Page-changing action is allowed on a loopback host ($url)"
		else
			REASON="${action} is allowed only on a tab at 127.0.0.1, localhost or [::1] (tab ${tab_id:-unknown} is at ${url:-an unrecorded URL}). Ask the user to perform this action."
		fi
		;;
	*)
		REASON="Only scroll, scroll_to, screenshot, zoom, hover and wait are allowed for ${TOOL_NAME}, plus page-changing actions on a loopback host (got: ${action:-unknown}). Ask the user to perform this action."
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
