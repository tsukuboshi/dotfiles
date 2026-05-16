## Required

- [Claude Code \- Anthropic](https://docs.anthropic.com/en/docs/claude-code)
- [apm \- Agent Package Manager](https://microsoft.github.io/apm/) (installed via `brew bundle --global`)

## Setup Claude Code

1. Execute genai setup script with the agent option set to claude.

```bash
./genai/setup.sh -a claude
```

`setup.sh` symlinks `~/.apm` to `genai/apm/`, then runs `apm install -g` to deploy external skills directly into `~/.claude/skills/`. Self-authored skills under `skills/` continue to be symlinked individually into `~/.claude/skills/`.

## Managing external skills with apm

External skills are declared via [apm](https://microsoft.github.io/apm/). The manifest and lockfile live under `genai/apm/` and are version-controlled in this dotfiles repository.

### Add

```bash
apm install -g owner/repo/skill-name
```

`genai/apm/apm.yml` and `genai/apm/apm.lock.yaml` are updated — commit both. The skill is deployed to `~/.claude/skills/<name>/` immediately.

### Update

```bash
apm update -g
```

### Remove

Delete the corresponding line from `genai/apm/apm.yml`, then:

```bash
apm install -g
trash ~/.claude/skills/<removed-skill-name>
```
