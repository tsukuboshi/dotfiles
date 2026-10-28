#!/bin/bash
# Run the post-edit hook's formatters and linters over every tracked file.
# The hook only sees the files an agent edits, so CI runs this to catch files
# edited by hand. Formatters rewrite files in place, and the closing git diff
# reports what they changed, so run it on a clean working tree.
# Usage: bash .github/scripts/lint-tracked-files.sh
set -u

root=$(git rev-parse --show-toplevel) || exit 1
cd "$root" || exit 1
hook="${root}/genai/hooks/post-edit-fmt.sh"

# Files another tool owns and rewrites: herdr overwrites its integration
# script on every update, so formatting it here would not last.
excluded=(
	genai/hooks/herdr-agent-state.sh
)

is_excluded() {
	local path
	for path in "${excluded[@]}"; do
		[[ "$1" == "$path" ]] && return 0
	done
	return 1
}

status=0
while IFS= read -r -d '' file; do
	is_excluded "$file" && continue
	output=$(jq -n --arg f "${root}/${file}" '{tool_name: "Edit", tool_input: {file_path: $f}}' |
		bash "$hook" 2>&1)
	rc=$?
	if ((rc != 0)); then
		printf '== %s (exit %d)\n%s\n' "$file" "$rc" "$output"
		status=1
	fi
done < <(git ls-files -z)

if ! git diff --exit-code --stat; then
	echo "lint-tracked-files: the formatters rewrote the files above; run them locally and commit the result"
	status=1
fi
exit "$status"
