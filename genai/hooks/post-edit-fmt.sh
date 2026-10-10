#!/bin/bash
# PostToolUse hook: Run linter/formatter when supported files are edited
# Supports both Claude Code (Edit/Write/MultiEdit) and Codex (apply_patch)

INPUT=$(cat)
TOOL_NAME=$(jq -r '.tool_name // empty' <<<"$INPUT")
TOOL_COMMAND=$(jq -r '.tool_input.command // empty' <<<"$INPUT")

# Formatters that were called for but could not run. Reported at exit so a
# broken toolchain surfaces instead of leaving files silently unformatted.
MISSING=()

# Lint findings left after auto-fixing. Claude Code and Codex hand a
# PostToolUse hook's stderr to the model only on exit 2, so these are
# reported that way for the agent to fix in its next edit.
FINDINGS=()

# Resolve a tool, preferring the project's node_modules/.bin over PATH so
# pnpm-managed versions win over anything installed globally.
resolve_bin() {
	local name=$1 dir=$2
	while [[ -n "$dir" && "$dir" != "/" ]]; do
		if [[ -x "${dir}/node_modules/.bin/${name}" ]]; then
			printf '%s\n' "${dir}/node_modules/.bin/${name}"
			return 0
		fi
		dir=$(dirname "$dir")
	done
	command -v "$name" 2>/dev/null
}

# True when an ancestor of $1 holds any of the remaining arguments.
has_project_file() {
	local dir=$1 name
	shift
	while [[ -n "$dir" && "$dir" != "/" ]]; do
		for name in "$@"; do
			[[ -e "${dir}/${name}" ]] && return 0
		done
		dir=$(dirname "$dir")
	done
	return 1
}

run_tool() {
	local name=$1 dir=$2
	shift 2
	local bin
	bin=$(resolve_bin "$name" "$dir")
	if [[ -z "$bin" ]]; then
		MISSING+=("$name")
		return 0
	fi
	local output
	output=$("$bin" "$@" 2>&1) && return 0
	# A non-zero exit usually means lint findings, so probe before blaming the
	# tool: only one that cannot run at all counts as unavailable. This catches
	# a stale shim that resolves on PATH but fails to execute.
	if "$bin" --version >/dev/null 2>&1; then
		FINDINGS+=("[${name}] ${output}")
	else
		MISSING+=("$name")
	fi
	return 0
}

format_file() {
	local file_path="$1"

	[[ -z "$file_path" || ! -f "$file_path" ]] && return 0

	local dir
	dir=$(cd "$(dirname "$file_path")" 2>/dev/null && pwd) || return 0

	case "$file_path" in
	*.tf)
		run_tool terraform "$dir" fmt "$file_path"
		;;
	*.py)
		run_tool ruff "$dir" check --fix "$file_path"
		run_tool ruff "$dir" format "$file_path"
		;;
	*.ts | *.tsx | *.js | *.jsx | *.json)
		# Only projects that configure biome are expected to have it.
		if has_project_file "$dir" biome.json biome.jsonc; then
			run_tool biome "$dir" check --fix "$file_path"
		fi
		;;
	*.md)
		# MD034 rewrites bare URLs; MD013 and MD025 fight the Japanese prose
		# and the per-step h1 structure these documents are written in.
		run_tool markdownlint "$dir" \
			--fix --disable MD034 MD013 MD025 -- "$file_path"
		;;
	*.sh | *.bash)
		run_tool shfmt "$dir" -w "$file_path"
		run_tool shellcheck "$dir" "$file_path"
		;;
	*/.github/workflows/*.yml | */.github/workflows/*.yaml)
		# Offline keeps zizmor inside the hook timeout; its online audits
		# are left to manual runs with GH_TOKEN.
		run_tool actionlint "$dir" "$file_path"
		run_tool zizmor "$dir" --offline --quiet --no-progress "$file_path"
		;;
	*/action.yml | */action.yaml)
		# actionlint cannot take action metadata as an argument.
		run_tool zizmor "$dir" --offline --quiet --no-progress "$file_path"
		;;
	esac
}

if [[ "$TOOL_NAME" == "apply_patch" ]]; then
	while IFS= read -r file_path; do
		format_file "$file_path"
	done < <(
		awk '
			/^\*\*\* (Add|Update) File: / { sub(/^\*\*\* (Add|Update) File: /, ""); print }
			/^\*\*\* Move to: / { sub(/^\*\*\* Move to: /, ""); print }
		' <<<"$TOOL_COMMAND" | sort -u
	)
else
	FILE_PATH=$(jq -r '.tool_input.file_path // empty' <<<"$INPUT")
	format_file "$FILE_PATH"
fi

if ((${#MISSING[@]} > 0)); then
	names=$(printf '%s\n' "${MISSING[@]}" | sort -u | paste -sd', ' -)
	printf 'post-edit-fmt: %s unavailable; file left unformatted\n' "$names" >&2
fi

if ((${#FINDINGS[@]} > 0)); then
	printf 'post-edit-fmt: fix these lint findings\n' >&2
	printf '%s\n' "${FINDINGS[@]}" >&2
	exit 2
fi

((${#MISSING[@]} > 0)) && exit 1
exit 0
