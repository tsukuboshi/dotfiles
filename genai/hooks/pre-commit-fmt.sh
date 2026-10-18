#!/bin/bash
# PreToolUse hook: Run formatters on staged files before git commit
# Supports both Claude Code and Codex CLI

# fmt_* helpers are dispatched indirectly via process_ext "$fmt".
# shellcheck disable=SC2329

INPUT=$(cat)
COMMAND=$(jq -r '.tool_input.command // empty' <<<"$INPUT")

# Detect caller: `turn_id` is a Codex-specific field
if jq -e '.turn_id' <<<"$INPUT" >/dev/null 2>&1; then
	CALLER="Codex"
else
	CALLER="Claude Code"
fi

# Only run for git commit commands
if ! grep -qE '^git\s+commit' <<<"$COMMAND"; then
	exit 0
fi

# Staged paths are relative to the repository root, and rumdl looks for its
# config upward from the cwd, so the formatters run from there.
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT" || exit 0

STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)
if [[ -z "$STAGED_FILES" ]]; then
	exit 0
fi

# Scan for secrets while the formatters run: gitleaks spends most of its
# time loading its rules, and no formatter adds a secret, so the index as
# staged before formatting carries the same leaks as after it.
# --redact keeps the secret itself out of the transcript the agent reads.
LEAKS_FILE=""
if command -v gitleaks >/dev/null 2>&1; then
	LEAKS_FILE=$(mktemp)
	gitleaks git --staged --no-banner --no-color --redact -v >"$LEAKS_FILE" 2>&1 &
	LEAKS_PID=$!
	trap 'kill "$LEAKS_PID" 2>/dev/null; rm -f "$LEAKS_FILE"' EXIT
fi

FORMATTED_FILES=()

# True when the repository root holds any of the given config files. An
# argument such as pyproject.toml:tool.rumdl counts only when the file
# declares that table.
has_root_config() {
	local spec name table
	for spec in "$@"; do
		name=${spec%%:*}
		[[ -f "$name" ]] || continue
		if [[ "$spec" == *:* ]]; then
			table=${spec#*:}
			grep -qE "^\[${table//./\\.}[].]" "$name" || continue
		fi
		return 0
	done
	return 1
}

# A project's own rumdl or markdownlint config replaces the rules disabled
# below, since --disable would override its list.
RUMDL_ARGS=()
has_root_config .rumdl.toml rumdl.toml .config/rumdl.toml pyproject.toml:tool.rumdl \
	.markdownlint-cli2.jsonc .markdownlint-cli2.yaml .markdownlint-cli2.yml \
	.markdownlint.json .markdownlint.yaml markdownlint.json ||
	RUMDL_ARGS=(--disable "MD034,MD013,MD025")

fmt_py() {
	xargs ruff check --fix <<<"$1" 2>/dev/null
	xargs ruff format <<<"$1" 2>/dev/null
}
fmt_js() { xargs biome check --fix <<<"$1" 2>/dev/null; }
fmt_tf() { xargs terraform fmt <<<"$1" 2>/dev/null; }
fmt_sh() { xargs shfmt -w <<<"$1" 2>/dev/null; }
# rumdl fixes MD025 by demoting later h1s, which breaks the per-step h1
# structure, so it is disabled along with the post-edit hook's rules.
fmt_md() { xargs rumdl fmt "${RUMDL_ARGS[@]}" -- <<<"$1" >/dev/null 2>&1; }
fmt_toml() { xargs taplo fmt <<<"$1" 2>/dev/null; }
fmt_sql() { xargs sqruff fix -f none <<<"$1" >/dev/null 2>&1; }

process_ext() {
	local pattern="$1" fmt="$2"
	local files
	files=$(grep -E "$pattern" <<<"$STAGED_FILES" || true)
	[[ -z "$files" ]] && return 0
	"$fmt" "$files"
	xargs git add <<<"$files"
	while IFS= read -r f; do FORMATTED_FILES+=("$f"); done <<<"$files"
}

# Run the project's own hooks with prek. Fixer hooks such as
# end-of-file-fixer exit non-zero after rewriting files, so the rewritten
# files are restaged and the hooks run once more; whatever still fails
# blocks the commit for the agent to fix.
run_prek() {
	local files=() before after output
	while IFS= read -r f; do files+=("$f"); done <<<"$STAGED_FILES"
	before=$(git -C "$REPO_ROOT" hash-object -- "${files[@]}")
	if ! prek run --cd "$REPO_ROOT" --files "${files[@]}" >/dev/null 2>&1; then
		git -C "$REPO_ROOT" add -- "${files[@]}"
		if ! output=$(prek run --cd "$REPO_ROOT" --files "${files[@]}" 2>&1); then
			printf 'Pre-commit (%s): prek hooks failed on the staged changes\n%s\n' \
				"${CALLER}" "${output}" >&2
			exit 2
		fi
	fi
	after=$(git -C "$REPO_ROOT" hash-object -- "${files[@]}")
	while IFS=$'\t' read -r f b a; do
		[[ "$b" != "$a" ]] && FORMATTED_FILES+=("$f")
	done < <(paste <(printf '%s\n' "${files[@]}") <(echo "$before") <(echo "$after"))
}

# Projects that declare their own hooks get those instead of the fixed
# formatter set below, so the commit is checked the way CI checks it and no
# formatter the project does not use rewrites its files.
if command -v prek >/dev/null 2>&1 &&
	[[ -f "$REPO_ROOT/.pre-commit-config.yaml" ||
		-f "$REPO_ROOT/.pre-commit-config.yml" ||
		-f "$REPO_ROOT/prek.toml" ]]; then
	run_prek
else
	process_ext '\.py$' fmt_py
	# Only projects that configure biome are expected to have it, as in the
	# post-edit hook.
	if has_root_config biome.json biome.jsonc; then
		process_ext '\.(ts|tsx|js|jsx|json)$' fmt_js
	fi
	process_ext '\.tf$' fmt_tf
	process_ext '\.(sh|bash)$' fmt_sh
	process_ext '\.md$' fmt_md
	process_ext '\.toml$' fmt_toml
	process_ext '\.sql$' fmt_sql
fi

# Block the commit when the staged changes carry a secret.
if [[ -n "$LEAKS_FILE" ]] && ! wait "$LEAKS_PID"; then
	printf 'Pre-commit (%s): gitleaks found secrets in the staged changes\n%s\n' \
		"${CALLER}" "$(<"$LEAKS_FILE")" >&2
	exit 2
fi

# Output result as JSON (both Claude Code and Codex accept `systemMessage`)
if [[ ${#FORMATTED_FILES[@]} -gt 0 ]]; then
	FILE_LIST=$(printf ', %s' "${FORMATTED_FILES[@]}")
	FILE_LIST=${FILE_LIST:2}
	printf '{"systemMessage":"Pre-commit (%s): formatted %d file(s): %s"}\n' \
		"${CALLER}" "${#FORMATTED_FILES[@]}" "${FILE_LIST}"
else
	printf '{"systemMessage":"Pre-commit (%s): no files matched formatting targets"}\n' \
		"${CALLER}"
fi

exit 0
