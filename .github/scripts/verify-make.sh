#!/bin/bash
# Check the state make and the setup scripts leave behind: every link points
# back into this repository and every Brewfile package is installed. The
# setup scripts print a failed link and go on, so CI checks the result here
# instead of trusting their exit codes.
# Usage: bash .github/scripts/verify-make.sh
set -u

root=$(git rev-parse --show-toplevel) || exit 1
FAILED=0
PASSED=0

pass() {
	PASSED=$((PASSED + 1))
}

fail() {
	FAILED=$((FAILED + 1))
	printf 'FAIL: %s\n  %s\n' "$1" "$2"
}

# expect_link <link> <source>
# Checks that link is a symlink resolving to the same file as source.
expect_link() {
	if [[ -L "$1" && "$1" -ef "$2" ]]; then
		pass
	else
		fail "${1} links to ${2#"${root}/"}" "got $(ls -ld "$1" 2>&1)"
	fi
}

# expect_dir_links <dir> <source-dir> <glob>
# Checks that every entry of source-dir matching glob is linked into dir.
# genai/setup.sh links only the directories '*/' matches and, for '*', only
# the regular files, so the rest is skipped here too.
expect_dir_links() {
	local entry
	for entry in "$2"/$3; do
		[[ "$3" == '*/' && -d "$entry" || -f "$entry" ]] || continue
		entry=${entry%/}
		expect_link "${1}/${entry##*/}" "$entry"
	done
}

# common/link.sh, which skips the same entries.
for dotfile in "${root}/common"/.??*; do
	case "${dotfile##*/}" in
	.git | .github | .DS_Store) continue ;;
	esac
	expect_link "${HOME}/${dotfile##*/}" "$dotfile"
done

# genai/setup.sh -l for each agent.
G="${root}/genai"
expect_link "${HOME}/.claude/CLAUDE.md" "${G}/AGENTS.md"
expect_link "${HOME}/.claude/settings.json" "${G}/settings.json"
expect_dir_links "${HOME}/.claude/skills" "${G}/skills" '*/'
expect_dir_links "${HOME}/.claude/rules" "${G}/rules" '*'
expect_link "${HOME}/.codex/AGENTS.md" "${G}/AGENTS.md"
expect_dir_links "${HOME}/.codex/skills" "${G}/skills" '*/'
expect_dir_links "${HOME}/.codex/rules" "${G}/rules" '*'
expect_link "${HOME}/.kiro/steering/AGENTS.md" "${G}/AGENTS.md"
expect_link "${HOME}/.kiro/agents/kiro_default.json" "${G}/kiro_default.json"
expect_dir_links "${HOME}/.kiro/skills" "${G}/skills" '*/'
expect_dir_links "${HOME}/.kiro/steering" "${G}/rules" '*'

# Codex writes to its config.toml, so setup.sh copies the managed part above
# the marker instead of linking it.
marker="# --- dotfiles managed config end ---"
managed() {
	awk -v marker="$marker" '$0 == marker { exit } { print }' "$1"
}
if [[ -f "${HOME}/.codex/config.toml" && ! -L "${HOME}/.codex/config.toml" ]] &&
	grep -Fxq "$marker" "${HOME}/.codex/config.toml" &&
	[[ "$(managed "${HOME}/.codex/config.toml")" == "$(managed "${G}/config.toml")" ]]; then
	pass
else
	fail "${HOME}/.codex/config.toml matches genai/config.toml above the marker" \
		"got $(ls -ld "${HOME}/.codex/config.toml" 2>&1)"
fi

# runtime/setup.sh -l, multiplexer/setup.sh and editor/setup.sh -l.
expect_link "${HOME}/.config/mise/config.toml" "${root}/runtime/config.toml"
expect_link "${HOME}/.config/herdr/config.toml" "${root}/multiplexer/config.toml"
expect_link "${HOME}/Library/Application Support/Code/User/settings.json" "${root}/editor/settings.json"

# sleepwatcher/setup.sh -s and -w write scripts that toggle Bluetooth.
for script in .sleep .wakeup; do
	if [[ -x "${HOME}/${script}" ]] && grep -q 'blueutil -p [01]$' "${HOME}/${script}"; then
		pass
	else
		fail "${HOME}/${script} toggles Bluetooth with blueutil" "got $(cat "${HOME}/${script}" 2>&1)"
	fi
done

# common/brew.sh. An installed package that is only outdated counts as
# installed (HOMEBREW_BUNDLE_NO_UPGRADE, https://docs.brew.sh/Manpage), so a
# machine with pending upgrades passes too.
if output=$(HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_BUNDLE_NO_UPGRADE=1 \
	brew bundle check --global --verbose 2>&1); then
	pass
else
	fail "every package in common/.Brewfile is installed" "$output"
fi

printf '%d passed, %d failed\n' "$PASSED" "$FAILED"
((FAILED == 0))
