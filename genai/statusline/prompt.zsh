#!/bin/zsh
# Prints the zsh prompt for the status line, for render.sh to run.
# The prompt parts are functions defined in .zshrc, and print -P expands
# zsh prompt escapes, so this part stays in zsh while render.sh is bash.

source ~/dotfiles/common/.zshrc

result=""
for func in "${PROMPT_PARTS[@]}"; do
	output=$($func)
	[ -n "$output" ] && result+="${result:+ }${output}"
done
# Keep -P and -n as separate flags: typos reads them bundled as a misspelling.
print -P -n "$result"
