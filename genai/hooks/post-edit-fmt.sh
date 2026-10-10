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

# Print the nearest ancestor of $1 that holds any of the remaining arguments.
find_project_dir() {
	local dir=$1 name
	shift
	while [[ -n "$dir" && "$dir" != "/" ]]; do
		for name in "$@"; do
			if [[ -e "${dir}/${name}" ]]; then
				printf '%s\n' "$dir"
				return 0
			fi
		done
		dir=$(dirname "$dir")
	done
	return 1
}

# True when an ancestor of $1 holds any of the remaining arguments.
has_project_file() {
	find_project_dir "$@" >/dev/null
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

# trivy resolves Terraform variables and modules across files, so it scans
# $target as a whole and only the misconfigurations in $file_path are kept.
# Only HIGH and CRITICAL are reported so the agent is not pushed into
# hardening every resource it touches.
run_trivy_config() {
	local file_path=$1 target=$2
	local bin
	bin=$(resolve_bin trivy "$target")
	if [[ -z "$bin" ]]; then
		MISSING+=("trivy")
		return 0
	fi
	local json findings
	if ! json=$("$bin" config --quiet --severity HIGH,CRITICAL --format json "$target" 2>/dev/null); then
		MISSING+=("trivy")
		return 0
	fi
	findings=$(jq -r --arg t "$(basename "$file_path")" '
		.Results[]? | select(.Target == $t) | .Misconfigurations[]?
		| "\($t):\(.CauseMetadata.StartLine // "-") \(.ID) (\(.Severity)): \(.Title | rtrimstr(".")). \(.Resolution)"
	' <<<"$json")
	[[ -n "$findings" ]] && FINDINGS+=("[trivy] ${findings}")
	return 0
}

# yamllint's default fails lines over 80 columns, which long commands in
# workflows hit all the time. -d would override a project's own config, so
# it is passed only when the project has none.
lint_yaml() {
	local file_path=$1 dir=$2
	local args=(-f parsable)
	if ! has_project_file "$dir" .yamllint .yamllint.yaml .yamllint.yml; then
		args+=(-d '{extends: default, rules: {line-length: {level: warning}}}')
	fi
	run_tool yamllint "$dir" "${args[@]}" "$file_path"
}

# sqruff fix exits non-zero while unfixable findings remain and also lists
# the ones it fixed, so its result is discarded and lint reports what is left.
lint_sql() {
	local file_path=$1 dir=$2
	local bin
	bin=$(resolve_bin sqruff "$dir")
	[[ -n "$bin" ]] && "$bin" fix -f none "$file_path" >/dev/null 2>&1
	run_tool sqruff "$dir" lint -n -q "$file_path"
}

format_file() {
	local file_path="$1"

	[[ -z "$file_path" || ! -f "$file_path" ]] && return 0

	local dir
	dir=$(cd "$(dirname "$file_path")" 2>/dev/null && pwd) || return 0

	case "$file_path" in
	# Lock files are generated, so edits to them are not the agent's to fix.
	*.lock.yaml | *.lock.yml | *-lock.yaml | *-lock.yml) ;;
	*.tf)
		run_tool terraform "$dir" fmt "$file_path"
		# tflint lints the whole module, and --filter matches the paths it
		# prints relative to the cwd, so run it from the module directory.
		# --fix is left out because it deletes declarations not yet used.
		pushd "$dir" >/dev/null || return 0
		run_tool tflint "$dir" --no-color --filter="$(basename "$file_path")"
		popd >/dev/null || return 0
		run_trivy_config "$file_path" "$dir"
		;;
	*/Dockerfile | */Dockerfile.* | *.dockerfile | */Containerfile)
		# info-level rules such as DL3059 are style advice, not defects.
		run_tool hadolint "$dir" --no-color --failure-threshold warning "$file_path"
		# A Dockerfile often sits at the repository root, so scan only the
		# file instead of everything below it.
		run_trivy_config "$file_path" "$file_path"
		;;
	*.py)
		run_tool ruff "$dir" check --fix "$file_path"
		run_tool ruff "$dir" format "$file_path"
		# Without a virtual environment every third-party import is
		# unresolved, and ty finds .venv only from the project it is given.
		local venv_root
		if venv_root=$(find_project_dir "$dir" .venv); then
			run_tool ty "$dir" check --project "$venv_root" \
				--output-format concise "$file_path"
		fi
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
		# fmt always exits 0, so only what check still finds is reported.
		run_tool rumdl "$dir" fmt --disable MD034,MD013,MD025 -- "$file_path"
		run_tool rumdl "$dir" check --disable MD034,MD013,MD025 -- "$file_path"
		;;
	*.sh | *.bash)
		run_tool shfmt "$dir" -w "$file_path"
		run_tool shellcheck "$dir" "$file_path"
		;;
	*.toml)
		# taplo logs every file it collects at INFO level.
		RUST_LOG=error run_tool taplo "$dir" fmt "$file_path"
		RUST_LOG=error run_tool taplo "$dir" check "$file_path"
		;;
	*.sql)
		lint_sql "$file_path" "$dir"
		;;
	*/.github/workflows/*.yml | */.github/workflows/*.yaml)
		# Offline keeps zizmor inside the hook timeout; its online audits
		# are left to manual runs with GH_TOKEN.
		lint_yaml "$file_path" "$dir"
		run_tool actionlint "$dir" "$file_path"
		run_tool zizmor "$dir" --offline --quiet --no-progress "$file_path"
		;;
	*/action.yml | */action.yaml)
		lint_yaml "$file_path" "$dir"
		# actionlint cannot take action metadata as an argument.
		run_tool zizmor "$dir" --offline --quiet --no-progress "$file_path"
		;;
	*.yml | *.yaml)
		lint_yaml "$file_path" "$dir"
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
