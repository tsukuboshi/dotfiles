#!/bin/bash
# Check that the agent settings parse and that every script they call exists.
# A settings.json that fails to parse turns off every hook in it, and a hook
# whose script was renamed fails on each tool call, and neither shows up in
# the lint job, which only formats these files.
# Usage: bash .github/scripts/test-settings.sh
set -u

root=$(git rev-parse --show-toplevel) || exit 1
cd "$root" || exit 1
FAILED=0
PASSED=0

pass() {
	PASSED=$((PASSED + 1))
}

fail() {
	FAILED=$((FAILED + 1))
	printf 'FAIL: %s\n  %s\n' "$1" "$2"
}

# devcontainer.json is JSONC, which the Dev Containers CLI reads with its
# comments, so jq cannot parse it.
while IFS= read -r -d '' file; do
	[[ "$file" == .devcontainer/devcontainer.json ]] && continue
	if output=$(jq empty "$file" 2>&1); then
		pass
	else
		fail "${file} parses as JSON" "$output"
	fi
done < <(git ls-files -z '*.json')

# The agents run hooks as ~/dotfiles/<path>, where the repository is cloned.
CONFIGS=(genai/settings.json genai/kiro_default.json genai/config.toml)
for config in "${CONFIGS[@]}"; do
	refs=0
	while IFS= read -r ref; do
		refs=$((refs + 1))
		path=${ref#\~/dotfiles/}
		if [[ -f "$path" ]]; then
			pass
		else
			fail "${config} calls ${ref}" "${path} is not in the repository"
		fi
	done < <(grep -oE '[~]/dotfiles/[^"'\'' ]+' "$config")
	# Each config runs hooks, so finding none means the paths are written
	# some other way and went unchecked.
	((refs > 0)) || fail "${config} calls scripts as ~/dotfiles/<path>" "no such reference found"
done

printf '%d passed, %d failed\n' "$PASSED" "$FAILED"
((FAILED == 0))
