#!/bin/bash
# Feed fixed files to the formatter hooks and check what each one reports.
# The lint job only shows that clean files pass, so a hook that stops
# blocking a bad file would go unnoticed without these cases.
# Fixtures are written under a fresh mktemp directory, which is left to the
# OS to clear, since a recursive rm is not used in scripts here.
# Usage: bash .github/scripts/test-fmt-hooks.sh
set -u

root=$(git rev-parse --show-toplevel) || exit 1
HOOKS_DIR="${root}/genai/hooks"
WORK=$(mktemp -d)
FAILED=0
PASSED=0

pass() {
	PASSED=$((PASSED + 1))
}

fail() {
	FAILED=$((FAILED + 1))
	printf 'FAIL: %s\n  %s\n' "$1" "$2"
}

# post_edit <file>
# Runs post-edit-fmt.sh on an Edit of the file, leaving its stdout and
# stderr in OUTPUT and its exit code in RC.
post_edit() {
	local input
	input=$(jq -n --arg f "$1" '{tool_name: "Edit", tool_input: {file_path: $f}}')
	OUTPUT=$(bash "${HOOKS_DIR}/post-edit-fmt.sh" <<<"${input}" 2>&1)
	RC=$?
}

# expect_rc <name> <want-rc> <want-message>
# Checks RC and that OUTPUT contains want-message, or is empty when
# want-message is empty.
expect_rc() {
	local name=$1 want_rc=$2 want=$3
	if ((RC == want_rc)) && { [[ -z "${want}" && -z "${OUTPUT}" ]] || [[ -n "${want}" && "${OUTPUT}" == *"${want}"* ]]; }; then
		pass
	else
		fail "${name}" "want exit ${want_rc} and '${want}', got exit ${RC}: ${OUTPUT}"
	fi
}

# post-edit-fmt.sh
mkdir -p "${WORK}/post-edit"
P="${WORK}/post-edit"

printf '#!/bin/bash\necho "hello"\n' >"${P}/clean.sh"
post_edit "${P}/clean.sh"
expect_rc "post-edit: a clean script passes silently" 0 ""

printf '#!/bin/bash\nif true; then\n    echo "hello"\nfi\n' >"${P}/unformatted.sh"
post_edit "${P}/unformatted.sh"
if ((RC == 0)) && [[ "$(<"${P}/unformatted.sh")" == $'#!/bin/bash\nif true; then\n\techo "hello"\nfi' ]]; then
	pass
else
	fail "post-edit: shfmt reindents a script with tabs" "got exit ${RC}: $(<"${P}/unformatted.sh")"
fi

printf "#!/bin/bash\necho \$1\n" >"${P}/unquoted.sh"
post_edit "${P}/unquoted.sh"
expect_rc "post-edit: a shellcheck finding is reported with exit 2" 2 "[shellcheck]"

# The linter finds the repository's .shellcheckrc by searching upward from
# the script, so a link to it beside a fixture stands in for a script here.
mkdir -p "${P}/strict"
ln -s "${root}/.shellcheckrc" "${P}/strict/.shellcheckrc"
printf "#!/bin/bash\necho \"\$HOME\"\n" >"${P}/strict/braces.sh"
post_edit "${P}/strict/braces.sh"
expect_rc "post-edit: the repository's .shellcheckrc enables the optional checks" 2 "SC2250"

# A directory linked from elsewhere, like the skills under ~/.claude, has no
# .shellcheckrc above the link; the linter resolves the link and finds it.
mkdir -p "${P}/strict/sub"
printf "#!/bin/bash\necho \"\$HOME\"\n" >"${P}/strict/sub/linked.sh"
ln -s "${P}/strict/sub" "${P}/linked-sub"
post_edit "${P}/linked-sub/linked.sh"
expect_rc "post-edit: a script edited through a linked directory gets the repository's .shellcheckrc" 2 "SC2250"

# ty has no fixes, so a type error is always left for the agent.
printf 'def f(x: int) -> str:\n    return x\n' >"${P}/typed.py"
post_edit "${P}/typed.py"
expect_rc "post-edit: a type error is reported by ty" 2 "[ty] typed.py:2:12: error[invalid-return-type]"

mkdir -p "${P}/ty-excluded" "${P}/ty-broken"
printf '[src]\nexclude = ["generated.py"]\n' >"${P}/ty-excluded/ty.toml"
printf 'def f(x: int) -> str:\n    return x\n' >"${P}/ty-excluded/generated.py"
post_edit "${P}/ty-excluded/generated.py"
if [[ "${OUTPUT}" != *"[ty]"* ]]; then
	pass
else
	fail "post-edit: a file the ty config excludes is not checked by ty" "got exit ${RC}: ${OUTPUT}"
fi

# A config ty cannot load is the tool failing, not a type error to fix.
printf '[rules\n' >"${P}/ty-broken/ty.toml"
printf 'x = 1\n' >"${P}/ty-broken/broken.py"
post_edit "${P}/ty-broken/broken.py"
if [[ "${OUTPUT}" == *"ty unavailable"* && "${OUTPUT}" != *"[ty]"* ]]; then
	pass
else
	fail "post-edit: a broken ty config is reported as ty unavailable" "got exit ${RC}: ${OUTPUT}"
fi

# Outside a crate, rustfmt parses as edition 2024 instead of its default 2015,
# where async is not a keyword.
printf 'async fn f( ) {}\n' >"${P}/standalone.rs"
post_edit "${P}/standalone.rs"
if ((RC == 0)) && [[ "$(<"${P}/standalone.rs")" == 'async fn f() {}' ]]; then
	pass
else
	fail "post-edit: rustfmt formats a file outside a crate as edition 2024" "got exit ${RC}: ${OUTPUT}"
fi

printf 'fn f( {}\n' >"${P}/unclosed.rs"
post_edit "${P}/unclosed.rs"
expect_rc "post-edit: a Rust parse error is reported against the file" 2 "[rustfmt] error: this file contains an unclosed delimiter"
if [[ "${OUTPUT}" == *"unclosed.rs:1"* ]]; then
	pass
else
	fail "post-edit: a Rust parse error names the file instead of stdin" "got exit ${RC}: ${OUTPUT}"
fi

# gen is reserved from edition 2024, so this parses only with the crate's 2021.
C="${P}/crate"
mkdir -p "${C}/src"
printf '[package]\nname = "fixture"\nversion = "0.1.0"\nedition = "2021"\n' >"${C}/Cargo.toml"
printf 'pub mod child;\n\npub fn f() -> u32 {\n    let gen = 1;\n    gen + 1\n}\n' >"${C}/src/lib.rs"
printf 'pub fn g( ) {}\n' >"${C}/src/child.rs"
post_edit "${C}/src/lib.rs"
expect_rc "post-edit: rustfmt parses with the crate's edition" 0 ""
if [[ "$(<"${C}/src/child.rs")" == 'pub fn g( ) {}' ]]; then
	pass
else
	fail "post-edit: rustfmt leaves the modules the file declares alone" "got: $(<"${C}/src/child.rs")"
fi

printf 'pub fn g() -> bool {\n    return true;\n}\n' >"${C}/src/child.rs"
post_edit "${C}/src/child.rs"
expect_rc "post-edit: a clippy finding is reported against the file" 2 \
	"[clippy] child.rs:2:5 warning[clippy::needless_return]"

printf "#!/bin/bash\nrm -rf \"\$1\"\n" >"${P}/recursive-rm.sh"
post_edit "${P}/recursive-rm.sh"
expect_rc "post-edit: a recursive rm is reported by ast-grep" 2 "sh-no-recursive-rm"

# Assembled at run time so typos does not flag this file itself.
misspelling="te""h"
printf '# Notes\n\nSee %s docs.\n' "${misspelling}" >"${P}/notes.md"
post_edit "${P}/notes.md"
expect_rc "post-edit: a misspelling in Markdown is reported by typos" 2 "[typos]"

printf 'name: %s\n' "${misspelling}" >"${P}/deps.lock.yaml"
post_edit "${P}/deps.lock.yaml"
expect_rc "post-edit: a lock file is left alone" 0 ""

# The linter rejects zsh outright (SC1071), so it must not see this script.
printf '#!/bin/zsh\nprint -P "%%F{red}hello%%f"\n' >"${P}/prompt.sh"
post_edit "${P}/prompt.sh"
expect_rc "post-edit: a zsh script is not passed to shellcheck" 0 ""

printf '#!/bin/zsh\nif true; then\n\techo "hello"\n' >"${P}/broken.sh"
post_edit "${P}/broken.sh"
expect_rc "post-edit: a zsh script with a syntax error is reported" 2 "[zsh]"

printf 'if true; then\n\techo "hello"\n' >"${P}/.zshrc"
post_edit "${P}/.zshrc"
expect_rc "post-edit: a .zshrc with a syntax error is reported" 2 "[zsh]"

# Startup files hold interactive shortcuts, which the script rules leave alone.
mkdir -p "${P}/zdotdir"
printf "function gcl () {\n  git clean -df \"\${1:-.}\"\n}\n" >"${P}/zdotdir/.zlogin"
post_edit "${P}/zdotdir/.zlogin"
expect_rc "post-edit: a git shortcut in a .zlogin is not checked by ast-grep" 0 ""

printf "#!/bin/zsh\nrm -rf \"\$1\"\n" >"${P}/cleanup.zsh"
post_edit "${P}/cleanup.zsh"
expect_rc "post-edit: a recursive rm in a .zsh script is reported by ast-grep" 2 "sh-no-recursive-rm"

# Codex reports the edited files inside the patch body, one per header.
printf '#!/bin/bash\nif true; then\n    echo "hello"\nfi\n' >"${P}/patched.sh"
printf '# Notes\n\nSee %s docs.\n' "${misspelling}" >"${P}/patched.md"
input=$(jq -n --arg sh "${P}/patched.sh" --arg md "${P}/patched.md" '{
	tool_name: "apply_patch",
	tool_input: {command: "*** Begin Patch\n*** Add File: \($sh)\n+x\n*** Update File: \($md)\n@@\n+x\n*** End Patch"}
}')
OUTPUT=$(bash "${HOOKS_DIR}/post-edit-fmt.sh" <<<"${input}" 2>&1)
RC=$?
if ((RC == 2)) && [[ "${OUTPUT}" == *"[typos]"* && "$(<"${P}/patched.sh")" == *$'\techo'* ]]; then
	pass
else
	fail "post-edit: apply_patch checks every file the patch names" "got exit ${RC}: ${OUTPUT}"
fi

# A PATH holding only the commands the hook itself needs, so each linter
# called for is reported missing even where the runner has one in /usr/bin.
bare_bin="${WORK}/bare-bin"
mkdir -p "${bare_bin}"
for cmd in cat jq dirname sort paste sed grep awk; do
	cmd_path=$(command -v "${cmd}")
	ln -s "${cmd_path}" "${bare_bin}/${cmd}"
done
input=$(jq -n --arg f "${P}/clean.sh" '{tool_name: "Edit", tool_input: {file_path: $f}}')
OUTPUT=$(PATH="${bare_bin}" "${BASH}" "${HOOKS_DIR}/post-edit-fmt.sh" <<<"${input}" 2>&1)
RC=$?
expect_rc "post-edit: missing linters are listed with exit 1" 1 \
	"ast-grep, shellcheck, shfmt, typos unavailable"

# pre-commit-fmt.sh
COMMIT_INPUT='{"tool_name": "Bash", "tool_input": {"command": "git commit -m test"}}'

# new_repo
# Creates an empty repository under WORK and leaves its path in REPO.
# --template= keeps the user's git hooks and templates out of it.
new_repo() {
	REPO=$(mktemp -d "${WORK}/repo.XXXXXX")
	git -C "${REPO}" init -q --template=
}

# pre_commit [input]
# Runs pre-commit-fmt.sh from REPO on a git commit, or on the input given,
# leaving its stdout and stderr in OUTPUT and its exit code in RC.
pre_commit() {
	OUTPUT=$(cd "${REPO}" && printf '%s' "${1:-${COMMIT_INPUT}}" | bash "${HOOKS_DIR}/pre-commit-fmt.sh" 2>&1)
	RC=$?
}

new_repo
pre_commit '{"tool_name": "Bash", "tool_input": {"command": "git status"}}'
expect_rc "pre-commit: commands other than git commit pass" 0 ""

pre_commit
expect_rc "pre-commit: a commit with nothing staged passes" 0 ""

new_repo
printf '#!/bin/bash\nif true; then\n    echo "hello"\nfi\n' >"${REPO}/fmt.sh"
git -C "${REPO}" add fmt.sh
pre_commit
staged=$(git -C "${REPO}" show :fmt.sh)
if ((RC == 0)) && [[ "${OUTPUT}" == *"formatted 1 file(s): fmt.sh"* && "${staged}" == *$'\techo'* ]]; then
	pass
else
	fail "pre-commit: a staged script is formatted and restaged" "got exit ${RC}: ${OUTPUT}"
fi

new_repo
mkdir -p "${REPO}/src"
printf '[package]\nname = "fixture"\nversion = "0.1.0"\nedition = "2021"\n' >"${REPO}/Cargo.toml"
printf 'pub mod child;\n\npub fn f( ) -> u32 {\n    let gen = 1;\n    gen + 1\n}\n' >"${REPO}/src/lib.rs"
printf 'pub fn g( ) {}\n' >"${REPO}/src/child.rs"
git -C "${REPO}" add src/lib.rs
pre_commit
staged=$(git -C "${REPO}" show :src/lib.rs)
if ((RC == 0)) && [[ "${staged}" == *'pub fn f() -> u32 {'* && "$(<"${REPO}/src/child.rs")" == 'pub fn g( ) {}' ]]; then
	pass
else
	fail "pre-commit: a staged Rust file alone is formatted with its crate's edition" "got exit ${RC}: ${OUTPUT}"
fi

new_repo
printf '#!/bin/bash\nif true; then\n    echo "hello"\nfi\n' >"${REPO}/partial.sh"
git -C "${REPO}" add partial.sh
printf 'echo "unstaged"\n' >>"${REPO}/partial.sh"
pre_commit
staged=$(git -C "${REPO}" show :partial.sh)
if ((RC == 0)) && [[ "${OUTPUT}" == *"left partially staged file(s) unformatted: partial.sh"* &&
	"${staged}" == *"    echo"* ]]; then
	pass
else
	fail "pre-commit: a partially staged file is left as staged" "got exit ${RC}: ${OUTPUT}"
fi

new_repo
# Assembled at run time so the commit hook does not flag this file itself.
token="ghp""_r7mqx2lk9vb4nc8zt1wy6hd3fj5ps0ga2k7q"
printf 'token = "%s"\n' "${token}" >"${REPO}/config.txt"
git -C "${REPO}" add config.txt
pre_commit
expect_rc "pre-commit: a staged secret blocks the commit" 2 "gitleaks found secrets"

new_repo
printf "#!/bin/bash\nrm -rf \"\$1\"\n" >"${REPO}/clean.sh"
git -C "${REPO}" add clean.sh
pre_commit
expect_rc "pre-commit: a recursive rm blocks the commit" 2 "sh-no-recursive-rm"

new_repo
printf '# Notes\n\nSee %s docs.\n' "${misspelling}" >"${REPO}/notes.md"
git -C "${REPO}" add notes.md
pre_commit
expect_rc "pre-commit: a misspelling blocks the commit" 2 "typos found misspellings"

printf '%d passed, %d failed\n' "${PASSED}" "${FAILED}"
((FAILED == 0))
