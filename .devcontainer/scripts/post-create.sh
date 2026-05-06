#!/usr/bin/env bash
# post-create.sh
# Setup script that wires up the host dotfiles when the devcontainer is first created.
# - Assumes the dotfiles repo is read-only bind-mounted at ~/dotfiles

set -euo pipefail

DOTFILES="$HOME/dotfiles"

if [[ ! -d "$DOTFILES" ]]; then
	echo "WARNING: $DOTFILES not found. Check the bind-mount configuration." >&2
	exit 0
fi

echo "=== post-create.sh: wiring up dotfiles ==="

# ---------- Shell (zsh + .zshrc are required because statusline.sh sources common/.zshrc) ----------
# .gitconfig contains macOS-specific settings (osxkeychain, code --wait), so it is
# handled separately below using [include].
echo "--- symlink shell dotfiles ---"
for src in "$DOTFILES/common/".??*; do
	name="$(basename "$src")"
	case "$name" in
	.git | .github | .DS_Store | .Brewfile | .gitconfig) continue ;;
	esac
	ln -fsn "$src" "$HOME/$name"
done

# ---------- .gitconfig (include the host config, override container-specific settings) ----------
echo "--- generate container .gitconfig ---"
cat >"$HOME/.gitconfig" <<EOF
[include]
	path = $DOTFILES/common/.gitconfig
[credential]
	helper = store
[core]
	editor = vim
EOF

# .stCommitMsg (referenced by host .gitconfig commit.template; create an empty one to avoid commit errors)
touch "$HOME/.stCommitMsg"

# git-secrets template directory (referenced by [init].templatedir)
git secrets --install -f "$HOME/.git-templates/git-secrets" >/dev/null

# ---------- mise (symlink runtime/config.toml and install runtimes) ----------
echo "--- mise setup ---"
mkdir -p "$HOME/.config/mise"
ln -fsn "$DOTFILES/runtime/config.toml" "$HOME/.config/mise/config.toml"
mise trust "$HOME/.config/mise/config.toml"
mise install

# ---------- Claude config (CLAUDE.md / settings.json / skills / rules) ----------
echo "--- run genai/setup.sh -l ---"
bash "$DOTFILES/genai/setup.sh" -l

# ---------- markdownlint required by hooks (installed via mise-managed node) ----------
echo "--- npm install markdownlint-cli ---"
mise exec -- npm install -g markdownlint-cli

# ---------- VS Code editor settings & extensions (single source of truth: editor/) ----------
echo "--- link editor settings ---"
mkdir -p "$HOME/.vscode-server/data/Machine"
ln -fsn "$DOTFILES/editor/settings.json" "$HOME/.vscode-server/data/Machine/settings.json"

echo "--- install editor extensions ---"
if command -v code >/dev/null 2>&1; then
	while read -r ext; do
		[ -z "$ext" ] && continue
		code --install-extension "$ext" --force || true
	done <"$DOTFILES/editor/extensions"
else
	echo "WARNING: 'code' command not found; skipping extension install" >&2
fi

echo "=== post-create.sh done ==="
