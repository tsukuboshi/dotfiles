#!/bin/bash
# PostToolUse hook: Run linter/formatter when supported files are edited
# Supports both Claude Code (Edit/Write/MultiEdit) and Codex (apply_patch)

INPUT=$(cat)
# One jq call reads both fields, since each process spawned here delays the
# agent after every edit. The patch body is multi-line, so it is read only
# for apply_patch.
{
	IFS= read -r TOOL_NAME
	IFS= read -r FILE_PATH
} < <(jq -r '(.tool_name // ""), (.tool_input.file_path // "")' <<<"$INPUT")

# Formatters that were called for but could not run. Reported at exit so a
# broken toolchain surfaces instead of leaving files silently unformatted.
MISSING=()

# Lint findings left after auto-fixing. Claude Code and Codex hand a
# PostToolUse hook's stderr to the model only on exit 2, so these are
# reported that way for the agent to fix in its next edit.
FINDINGS=()

# Directory walks below step up with ${dir%/*} instead of $(dirname), which
# forked once per level and took half of the hook's run time. $dir is always
# absolute, and the walk stops before "/" either way.

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
		dir=${dir%/*}
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
		dir=${dir%/*}
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

# golangci-lint resolves types per package, so the whole package in $dir is
# linted and only the issues in $file_path are kept, as with trivy below.
# Paths in its output are relative to the cwd, and it searches for its config
# upward from there, so it runs from the package directory.
lint_go() {
	local file_path=$1 dir=$2
	local bin
	bin=$(resolve_bin golangci-lint "$dir")
	if [[ -z "$bin" ]]; then
		MISSING+=("golangci-lint")
		return 0
	fi
	pushd "$dir" >/dev/null || return 0
	"$bin" fmt "$file_path" >/dev/null 2>&1
	local json findings
	json=$("$bin" run --output.json.path stdout --show-stats=false ./ 2>/dev/null)
	popd >/dev/null || return 0
	# Issues come as JSON on exit 0 and 1 alike; anything else means the run
	# itself failed.
	if ! findings=$(jq -r --arg t "${file_path##*/}" '
		.Issues[]? | select(.Pos.Filename == $t)
		| "\($t):\(.Pos.Line):\(.Pos.Column) \(.Text) (\(.FromLinter))"
	' <<<"$json" 2>/dev/null) || [[ -z "$json" ]]; then
		MISSING+=("golangci-lint")
		return 0
	fi
	[[ -n "$findings" ]] && FINDINGS+=("[golangci-lint] ${findings}")
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
	if config=$(find_config "${file_path%/*}" trivy.yaml); then
		args+=(--config "$config")
	else
		args+=(--severity "HIGH,CRITICAL")
	fi
	local json findings
	if ! json=$("$bin" "${args[@]}" "$target" 2>/dev/null); then
		MISSING+=("trivy")
		return 0
	fi
	findings=$(jq -r --arg t "${file_path##*/}" '
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

# kubeconform validates Kubernetes manifests against the API's schemas, and
# custom resources against those in the CRDs-catalog; kinds in neither, such
# as a Kustomization, are skipped. -strict rejects unknown fields, which is
# how a misspelled one is caught. A manifest is told from other YAML by its
# top-level apiVersion and kind, and a Helm template, which kubeconform
# cannot parse, by its {{ }}. Schemas are cached, since every validation
# would download them otherwise; one that cannot be downloaded leaves the
# tool unavailable rather than the manifest invalid.
KUBECONFORM_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/kubeconform"
lint_k8s() {
	local file_path=$1 dir=$2
	awk '/\{\{/ { t = 1 } /^apiVersion:/ { a = 1 } /^kind:/ { k = 1 }
		END { exit !(a && k && !t) }' "$file_path" || return 0
	local bin json findings
	bin=$(resolve_bin kubeconform "$dir")
	if [[ -z "$bin" ]]; then
		MISSING+=("kubeconform")
		return 0
	fi
	mkdir -p "$KUBECONFORM_CACHE"
	json=$("$bin" -strict -ignore-missing-schemas -cache "$KUBECONFORM_CACHE" -output json \
		-schema-location default \
		-schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
		"$file_path" 2>/dev/null)
	if [[ -z "$json" ]] ||
		jq -e 'any(.resources[]?; .msg | startswith("failed downloading schema"))' <<<"$json" >/dev/null 2>&1 ||
		! findings=$(jq -r --arg t "${file_path##*/}" '
			.resources[]? | select(.status == "statusInvalid" or .status == "statusError")
			| "\($t) \(.kind)/\(.name): " as $p
			| if .validationErrors then .validationErrors[] | $p + "\(.path) \(.msg)" else $p + .msg end
		' <<<"$json" 2>/dev/null); then
		MISSING+=("kubeconform")
		return 0
	fi
	[[ -n "$findings" ]] && FINDINGS+=("[kubeconform] ${findings}")
	return 0
}

# ast-grep checks the custom rules in genai/lint/ast-grep for what the other
# linters miss, or a project's own sgconfig.yml in their place. scan exits
# non-zero only on error-level findings, so warnings are read from its JSON
# instead of the exit code, which run_tool relies on.
AST_GREP_CONFIG="${BASH_SOURCE[0]%/*}/../lint/ast-grep/sgconfig.yml"
lint_ast_grep() {
	local file_path=$1 dir=$2
	local bin config json findings
	bin=$(resolve_bin ast-grep "$dir")
	if [[ -z "$bin" ]]; then
		MISSING+=("ast-grep")
		return 0
	fi
	config=$(find_config "$dir" sgconfig.yml sgconfig.yaml) || config=$AST_GREP_CONFIG
	json=$("$bin" scan --config "$config" --color never --json=compact "$file_path" 2>/dev/null)
	if ! findings=$(jq -r --arg t "${file_path##*/}" '
		.[] | "\($t):\(.range.start.line + 1):\(.range.start.column + 1) \(.severity)[\(.ruleId)] \(.message)"
			+ (if .note then " " + (.note | gsub("\\s+"; " ") | rtrimstr(" ")) else "" end)
	' <<<"$json" 2>/dev/null) || [[ -z "$json" ]]; then
		MISSING+=("ast-grep")
		return 0
	fi
	[[ -n "$findings" ]] && FINDINGS+=("[ast-grep] ${findings}")
	return 0
}

# typos checks every file type for misspellings with its own defaults or the
# project's config, which it finds by itself. Fixes are left to the agent, since a
# suggested spelling can rename an identifier the code depends on. typos
# exits 2 on findings only, so any other failure means it could not run.
lint_typos() {
	local file_path=$1 dir=$2
	local bin output status
	bin=$(resolve_bin typos "$dir")
	if [[ -z "$bin" ]]; then
		MISSING+=("typos")
		return 0
	fi
	output=$("$bin" --force-exclude --format brief --color never -- "$file_path" 2>&1)
	status=$?
	case $status in
	0) ;;
	2) FINDINGS+=("[typos] ${output}") ;;
	*) MISSING+=("typos") ;;
	esac
	return 0
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
	file_path="${dir}/${file_path##*/}"

	# Lock files are generated, so edits to them are not the agent's to fix.
	case "$file_path" in
	*.lock | *.lock.yaml | *.lock.yml | *-lock.yaml | *-lock.yml) return 0 ;;
	esac

	lint_typos "$file_path" "$dir"

	local config
	case "$file_path" in
	*.py)
		# S adds the Bandit security rules even to a project's own config,
		# since the extend flags add to its selection instead of replacing
		# it. pytest checks with assert, so S101 is left out for test files.
		# F401 stays a finding instead of a fix: an edit that adds an import
		# before the code that uses it would otherwise lose the import. The
		# --config override extends the project's unfixable list, whereas
		# --unfixable would replace it.
		run_tool ruff "$dir" check --fix --extend-select S \
			--config "lint.extend-unfixable = ['F401']" \
			--extend-per-file-ignores '**/test_*.py:S101' \
			--extend-per-file-ignores '**/*_test.py:S101' \
			--extend-per-file-ignores '**/conftest.py:S101' \
			"$file_path"
		run_tool ruff "$dir" format "$file_path"
		lint_ast_grep "$file_path" "$dir"
		;;
	*.ts | *.tsx | *.js | *.jsx | *.json)
		# Only projects that configure biome are expected to have it.
		if has_project_file "$dir" biome.json biome.jsonc; then
			run_tool biome "$dir" check --fix "$file_path"
		fi
		;;
	*.go)
		# Outside a module, golangci-lint cannot load the package at all.
		has_project_file "$dir" go.mod && lint_go "$file_path" "$dir"
		;;
	*.tf)
		run_tool terraform "$dir" fmt "$file_path"
		# tflint lints the whole module, and --filter matches the paths it
		# prints relative to the cwd, so run it from the module directory.
		# --fix is left out because it deletes declarations not yet used.
		# tflint reads .tflint.hcl only from the cwd, so a project's config
		# at the repository root is passed explicitly.
		local tflint_args=(--no-color --filter="${file_path##*/}")
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
	*.sh | *.bash)
		run_tool shfmt "$dir" -w "$file_path"
		# zsh is rejected outright by the linter (SC1071), so a #!/bin/zsh .sh
		# would block every edit. The shebang is read with a builtin to avoid a fork.
		local shebang=""
		IFS= read -r shebang <"$file_path"
		[[ "$shebang" == '#!'*zsh* ]] ||
			run_tool shellcheck "$dir" "$file_path"
		# The Bash grammar also reads zsh, so ast-grep checks zsh scripts too.
		lint_ast_grep "$file_path" "$dir"
		;;
	*/.github/workflows/*.yml | */.github/workflows/*.yaml)
		# Offline keeps zizmor inside the hook timeout; its online audits
		# are left to manual runs with GH_TOKEN.
		lint_yaml "$file_path" "$dir"
		run_tool actionlint "$dir" "$file_path"
		run_tool zizmor "$dir" --offline --quiet --no-progress "$file_path"
		lint_ast_grep "$file_path" "$dir"
		;;
	*/action.yml | */action.yaml)
		lint_yaml "$file_path" "$dir"
		# actionlint cannot take action metadata as an argument.
		run_tool zizmor "$dir" --offline --quiet --no-progress "$file_path"
		lint_ast_grep "$file_path" "$dir"
		;;
	*.md)
		# Without a project config, MD034 rewrites bare URLs; MD013 and MD025
		# fight the Japanese prose and the per-step h1 structure these
		# documents are written in. MD041 rejects SKILL.md files, which open
		# with frontmatter and an instruction, and templates and READMEs
		# that open with an h2. rumdl searches for its config upward from
		# the cwd, so it runs from the file's directory.
		# fmt always exits 0, so only what check still finds is reported.
		local rumdl_args=()
		has_project_file "$dir" "${RUMDL_CONFIGS[@]}" ||
			rumdl_args+=(--disable "MD034,MD013,MD025,MD041")
		pushd "$dir" >/dev/null || return 0
		run_tool rumdl "$dir" fmt "${rumdl_args[@]}" -- "$file_path"
		run_tool rumdl "$dir" check "${rumdl_args[@]}" -- "$file_path"
		popd >/dev/null || return 0
		;;
	*.toml)
		# taplo logs every file it collects at INFO level.
		RUST_LOG=error run_tool taplo "$dir" fmt "$file_path"
		RUST_LOG=error run_tool taplo "$dir" check "$file_path"
		;;
	*.yml | *.yaml)
		# Files under a chart's templates/ are Go templates that render to
		# YAML, which ryl reports as syntax errors, so only the chart's
		# Chart.yaml and values.yaml are linted. A subchart's are matched too,
		# since the shortest suffix leaves charts/<name>.
		[[ "$file_path" == */templates/* && -f "${file_path%/templates/*}/Chart.yaml" ]] ||
			lint_yaml "$file_path" "$dir"
		lint_k8s "$file_path" "$dir"
		lint_ast_grep "$file_path" "$dir"
		;;
	*.sql)
		lint_sql "$file_path" "$dir"
		;;
	esac
}

if [[ "$TOOL_NAME" == "apply_patch" ]]; then
	TOOL_COMMAND=$(jq -r '.tool_input.command // empty' <<<"$INPUT")
	while IFS= read -r file_path; do
		format_file "$file_path"
	done < <(
		awk '
			/^\*\*\* (Add|Update) File: / { sub(/^\*\*\* (Add|Update) File: /, ""); print }
			/^\*\*\* Move to: / { sub(/^\*\*\* Move to: /, ""); print }
		' <<<"$TOOL_COMMAND" | sort -u
	)
else
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
