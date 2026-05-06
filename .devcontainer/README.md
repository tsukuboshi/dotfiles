## Required

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) or [Rancher Desktop](https://rancherdesktop.io/)
- [Visual Studio Code](https://code.visualstudio.com/)
- [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- This repository cloned at `~/dotfiles` on the host (read-only bind-mounted into the container)

## Setup Dev Container

1. Open the target project in Visual Studio Code.
2. Replace the project's `.devcontainer/` with this one, or symlink it.

```bash
ln -fsn ~/dotfiles/.devcontainer <target-project>/.devcontainer
```

3. Press "shift + command + P".
4. Search and select "Dev Containers: Reopen in Container".
5. Wait for the initial build and `postCreateCommand` (mise install / Claude config symlinks / git-secrets template) to finish.

## Verify Setup

1. Open a terminal inside the container.
2. Confirm runtimes, dotfiles wiring, and hook CLIs are in place.

```bash
mise current
ls -la ~/.claude/CLAUDE.md ~/.claude/settings.json ~/.claude/rules
which shellcheck shfmt markdownlint ripgrep git-secrets
```

3. Confirm editor settings and extensions are wired up to the `editor/` dotfiles.

```bash
# settings.json should be symlinked to ~/dotfiles/editor/settings.json
readlink ~/.vscode-server/data/Machine/settings.json

# All extensions listed in editor/extensions should be installed.
# (No output means everything is installed.)
comm -23 \
  <(sort ~/dotfiles/editor/extensions | tr '[:upper:]' '[:lower:]') \
  <(code --list-extensions | sort | tr '[:upper:]' '[:lower:]')
```

## CLI Smoke Test (optional)

To validate the image build and `postCreateCommand` without launching VS Code, use the [Dev Containers CLI](https://github.com/devcontainers/cli).

```bash
npx -y @devcontainers/cli up --workspace-folder ~/dotfiles --remove-existing-container
npx -y @devcontainers/cli exec --workspace-folder ~/dotfiles bash
```

Caveats when using the CLI instead of VS Code:

- `code` is provided by VS Code Server, which is only installed when VS Code attaches. Extension install in `postCreateCommand` is skipped with a warning. The `settings.json` symlink still works.
- `postStartCommand` (`init-firewall.sh`) fails because the CLI does not pass through the same sudoers/network setup VS Code Remote uses. This is expected in CLI mode.

## Update Allowed Domains

To allow additional outbound traffic, edit `ALLOWED_DOMAINS` in `scripts/init-firewall.sh` and rebuild the container.

1. Edit `scripts/init-firewall.sh`.
2. Press "shift + command + P" and select "Dev Containers: Rebuild Container".

## Reset Caches

Persistent caches for mise / npm / uv / Terraform plugins live in named volumes. To wipe them completely, remove the volumes from the host.

```bash
docker volume ls --filter "name=claude-code-" --format '{{.Name}}' | xargs -r docker volume rm
```
