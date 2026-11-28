#!/bin/bash
# Records whether the agent is running, for the status line to show.
# Usage: agent-state.sh <action>, with the hook input on stdin.
#   run / idle   the main agent began or ended a turn: writes "<state> <epoch seconds>"
#   start        a session began: idle, forgetting subagents left by an earlier run
#   agent-start  a subagent began: adds it to the subagents still running
#   agent-stop   a subagent ended: removes it
#   end          the session ended: removes its files
# genai/statusline/state-path.sh sets where, and genai/statusline/render.sh reads it.
# Prints nothing, since UserPromptSubmit puts stdout into the model's context.

source "$(dirname "${BASH_SOURCE[0]}")/../statusline/state-path.sh"

ACTION=$1
INPUT=$(cat)

# The unit separator keeps an empty field in place, where a tab, being
# whitespace to read, would let the next field slide into it.
# BG_SUBAGENTS is empty unless the input lists background tasks, as Stop does.
IFS=$'\x1f' read -r SESSION_ID AGENT_ID BG_SUBAGENTS < <(
	jq -r '[
	  (.session_id // "" | tostring),
	  (.agent_id // "" | tostring),
	  (.background_tasks | if type == "array" then map(select(.type? == "subagent")) | length | tostring else "" end)
	] | join("\u001f")' <<<"${INPUT}" 2>/dev/null || true
)

agent_state_path "${SESSION_ID}" || exit 0
AGENTS_DIR="${AGENT_STATE_PATH}.agents"

# write_state <state>
write_state() {
	local now tmp_file
	now=$(date +%s)
	mkdir -p "${AGENT_STATE_PATH%/*}" 2>/dev/null || return 0
	# Written whole and then moved, so render.sh never reads a half-written file.
	tmp_file=$(mktemp "${AGENT_STATE_PATH}.XXXXXX" 2>/dev/null) || return 0
	if ! { printf '%s %s\n' "$1" "${now}" >"${tmp_file}" &&
		mv -f "${tmp_file}" "${AGENT_STATE_PATH}" 2>/dev/null; }; then
		rm -f "${tmp_file}"
	fi
}

forget_subagents() {
	rm -f "${AGENTS_DIR}"/* 2>/dev/null
	rmdir "${AGENTS_DIR}" 2>/dev/null
}

case "${ACTION}" in
run | idle | start)
	# A subagent's own events say nothing about whether the main agent is running.
	[[ -n "${AGENT_ID}" ]] && exit 0
	if [[ "${ACTION}" == start ]]; then
		write_state idle
	else
		write_state "${ACTION}"
	fi
	# Stop lists the background work still running, so with no subagent among
	# it, any subagent recorded as running missed its SubagentStop.
	if [[ "${ACTION}" == start || "${BG_SUBAGENTS}" == 0 ]]; then
		forget_subagents
	fi
	;;
agent-start | agent-stop)
	[[ "${AGENT_ID}" =~ ^[A-Za-z0-9_-]+$ ]] || exit 0
	if [[ "${ACTION}" == agent-start ]]; then
		mkdir -p "${AGENTS_DIR}" 2>/dev/null && : >"${AGENTS_DIR}/${AGENT_ID}"
	else
		rm -f "${AGENTS_DIR}/${AGENT_ID}"
	fi
	;;
end)
	rm -f "${AGENT_STATE_PATH}"
	forget_subagents
	;;
*) ;;
esac

exit 0
