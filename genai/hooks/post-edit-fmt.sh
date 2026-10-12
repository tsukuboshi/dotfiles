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

# Resolve a tool, preferring the project's node_modules/.bin and .venv/bin
# over PATH so pnpm- and uv-managed versions win over anything installed
# globally, which a pinned version such as ruff's required-version rejects.
resolve_bin() {
	local name=$1 dir=$2 bin_dir
	while [[ -n "$dir" && "$dir" != "/" ]]; do
		for bin_dir in node_modules/.bin .venv/bin; do
			if [[ -x "${dir}/${bin_dir}/${name}" ]]; then
				printf '%s\n' "${dir}/${bin_dir}/${name}"
				return 0
			fi
		done
		dir=$(dirname "$dir")
	done
	command -v "$name" 2>/dev/null
}

# Print the nearest file among the remaining arguments in $1 or its
# ancestors. An argument such as pyproject.toml:tool.ruff counts only when
# the file declares that table, the way the tools themselves read it.
find_config() {
	local dir=$1 spec name table
	shift
	while [[ -n "$dir" && "$dir" != "/" ]]; do
		for spec in "$@"; do
			name=${spec%%:*}
			[[ -f "${dir}/${name}" ]] || continue
			if [[ "$spec" == *:* ]]; then
				table=${spec#*:}
				grep -qE "^\[${table//./\\.}[].]" "${dir}/${name}" || continue
			fi
			printf '%s\n' "${dir}/${name}"
			return 0
		done
		dir=$(dirname "$dir")
	done
	return 1
}

# True when $1 or an ancestor holds any of the remaining config files. The
# defaults below are passed as flags, which override a project's config, so
# they are passed only when this is false.
has_project_file() {
	find_config "$@" >/dev/null
}

RUMDL_CONFIGS=(.rumdl.toml rumdl.toml .config/rumdl.toml pyproject.toml:tool.rumdl
	.markdownlint-cli2.jsonc .markdownlint-cli2.yaml .markdownlint-cli2.yml
	.markdownlint.json .markdownlint.yaml markdownlint.json)

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
	# trivy reads trivy.yaml only from the cwd, so the project's is passed
	# explicitly and takes the place of the severity default.
	local args=(config --quiet --format json) config
	if config=$(find_config "$(dirname "$file_path")" trivy.yaml); then
		args+=(--config "$config")
	else
		args+=(--severity "HIGH,CRITICAL")
	fi
	local json findings
	if ! json=$("$bin" "${args[@]}" "$target" 2>/dev/null); then
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

# ryl enables no rules without a config, so yamllint's default preset is
# passed with its 80-column limit, which long commands in workflows hit all
# the time, lowered to a warning. -d would override a project's own config,
# so it is passed only when the project has none.
lint_yaml() {
	local file_path=$1 dir=$2
	local args=(check --fix -f parsable)
	if ! has_project_file "$dir" .ryl.toml ryl.toml .config/.ryl.toml .config/ryl.toml \
		.yamllint .yamllint.yaml .yamllint.yml; then
		args+=(-d '{extends: default, rules: {line-length: {level: warning}}}')
	fi
	run_tool ryl "$dir" "${args[@]}" "$file_path"
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
	# Codex passes paths relative to the cwd, which pushd below would break.
	file_path="${dir}/$(basename "$file_path")"

	local config
	case "$file_path" in
	# Lock files are generated, so edits to them are not the agent's to fix.
	*.lock.yaml | *.lock.yml | *-lock.yaml | *-lock.yml) ;;
	*.tf)
		run_tool terraform "$dir" fmt "$file_path"
		# tflint lints the whole module, and --filter matches the paths it
		# prints relative to the cwd, so run it from the module directory.
		# --fix is left out because it deletes declarations not yet used.
		# tflint reads .tflint.hcl only from the cwd, so a project's config
		# at the repository root is passed explicitly.
		local tflint_args=(--no-color --filter="$(basename "$file_path")")
		config=$(find_config "$dir" .tflint.hcl) && tflint_args+=(--config="$config")
		pushd "$dir" >/dev/null || return 0
		run_tool tflint "$dir" "${tflint_args[@]}"
		popd >/dev/null || return 0
		run_trivy_config "$file_path" "$dir"
		;;
	*/Dockerfile | */Dockerfile.* | *.dockerfile | */Containerfile)
		# hadolint reads .hadolint.yaml only from the cwd, so a project's
		# config is passed explicitly. Without one, info-level rules such as
		# DL3059 are style advice, not defects.
		if config=$(find_config "$dir" .hadolint.yaml .hadolint.yml); then
			run_tool hadolint "$dir" --no-color --config "$config" "$file_path"
		else
			run_tool hadolint "$dir" --no-color --failure-threshold warning "$file_path"
		fi
		# A Dockerfile often sits at the repository root, so scan only the
		# file instead of everything below it.
		run_trivy_config "$file_path" "$file_path"
		;;
	*.py)
		# S adds the Bandit security rules even to a project's own config,
		# since the extend flags add to its selection instead of replacing
		# it. pytest checks with assert, so S101 is left out for test files.
		run_tool ruff "$dir" check --fix --extend-select S \
			--extend-per-file-ignores '**/test_*.py:S101' \
			--extend-per-file-ignores '**/*_test.py:S101' \
			--extend-per-file-ignores '**/conftest.py:S101' \
			"$file_path"
		run_tool ruff "$dir" format "$file_path"
		;;
	*.ts | *.tsx | *.js | *.jsx | *.json)
		# Only projects that configure biome are expected to have it.
		if has_project_file "$dir" biome.json biome.jsonc; then
			run_tool biome "$dir" check --fix "$file_path"
		fi
		;;
	*.md)
		# Without a project config, MD034 rewrites bare URLs; MD013 and MD025
		# fight the Japanese prose and the per-step h1 structure these
		# documents are written in. rumdl searches for its config upward from
		# the cwd, so it runs from the file's directory.
		# fmt always exits 0, so only what check still finds is reported.
		local rumdl_args=()
		has_project_file "$dir" "${RUMDL_CONFIGS[@]}" ||
			rumdl_args+=(--disable "MD034,MD013,MD025")
		pushd "$dir" >/dev/null || return 0
		run_tool rumdl "$dir" fmt "${rumdl_args[@]}" -- "$file_path"
		run_tool rumdl "$dir" check "${rumdl_args[@]}" -- "$file_path"
		popd >/dev/null || return 0
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
