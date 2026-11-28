#!/bin/bash
# Where the agent state of a session is kept, sourced by genai/hooks/agent-state.sh,
# which writes it, and by render.sh, which reads it, so the two always agree.

# agent_state_path <session_id>
# Sets AGENT_STATE_PATH to the session's state file, or returns 1 for a
# session ID that is not a plain name, since it becomes a file name.
# The subagents still running are kept in "${AGENT_STATE_PATH}.agents/".
agent_state_path() {
	[[ "$1" =~ ^[A-Za-z0-9_-]+$ ]] || return 1
	# macOS gives each user their own TMPDIR, but the /tmp fallback is shared,
	# so the UID keeps users apart there.
	# shellcheck disable=SC2034 # read by the scripts that source this file
	AGENT_STATE_PATH="${CLAUDE_AGENT_STATE_DIR:-${TMPDIR:-/tmp}/claude-agent-state-${UID}}/$1"
}
