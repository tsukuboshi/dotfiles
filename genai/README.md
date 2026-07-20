## Required

- [Claude Code \- Anthropic](https://docs.anthropic.com/en/docs/claude-code)
- [Codex CLI \- OpenAI](https://developers.openai.com/codex/cli) (optional, only when using `-a codex`)
- [apm \- Agent Package Manager](https://microsoft.github.io/apm/) (installed via `brew bundle --global`)

## Setup Claude Code

1. Execute genai setup script with the agent option set to claude.

```bash
./genai/setup.sh -a claude
```

This links:

- `genai/AGENTS.md` → `~/.claude/CLAUDE.md` (global agent instructions)
- `genai/settings.json` → `~/.claude/settings.json` (permissions, hooks, status line, plugins)
- `genai/skills/*/` → `~/.claude/skills/<name>/` (self-authored skills)
- `genai/rules/*` → `~/.claude/rules/*` (language/tooling rules)
- apm-installed skills are deployed by `apm install -g` into `~/.claude/skills/` (per `targets:` pinned in `apm/apm.yml`)

## Setup Codex CLI

1. Execute genai setup script with the agent option set to codex.

```bash
./genai/setup.sh -a codex
```

This installs:

- `genai/AGENTS.md` → `~/.codex/AGENTS.md` (symlinked; global agent instructions)
- `genai/config.toml` → `~/.codex/config.toml` (**copied**; sandbox, hooks, status line)
- `genai/skills/*/` → `~/.codex/skills/<name>/` (symlinked; self-authored skills)
- `genai/rules/*` → `~/.codex/rules/*` (symlinked; language/tooling rules)
- apm-installed skills are deployed by `apm install -g` into `~/.agents/skills/` (cross-client location auto-discovered by Codex per [Codex skill discovery docs](https://developers.openai.com/codex/skills); per `targets:` pinned in `apm/apm.yml`)

`config.toml` is copied rather than symlinked because Codex writes per-project trust entries (`[projects.*]`) and NUX tooltip counters (`[tui.model_availability_nux]`) back to `~/.codex/config.toml` at runtime. Copying keeps that user- / machine-local state out of the dotfiles source tree; re-running setup overwrites whatever has accumulated since the previous install.

Note that Codex does not support custom status line commands (only the built-in items selected in `[tui]` are shown), so `scripts/statusline.sh` is intentionally not wired up for Codex.

## Setup Kiro CLI

1. Execute genai setup script with the agent option set to kiro.

```bash
./genai/setup.sh -a kiro
```

This links:

- `genai/AGENTS.md` → `~/.kiro/AGENTS.md` (symlinked; global agent instructions)
- `genai/kiro_default.json` → `~/.kiro/agents/kiro_default.json` (symlinked; agent config with hooks, tool settings, MCP servers)
- `genai/skills/*/` → `~/.kiro/skills/<name>/` (symlinked; self-authored skills)
- `genai/rules/*` → `~/.kiro/rules/*` (symlinked; language/tooling rules)
- apm-installed skills are deployed by `apm install -g` into `~/.agents/skills/` (per `targets:` pinned in `apm/apm.yml`)

### kiro_default.json

`genai/kiro_default.json` is the Kiro equivalent of Claude's `settings.json`. It configures the global default agent with:

| Claude `settings.json` | Kiro `kiro_default.json` |
|---|---|
| `permissions.allow` / `permissions.deny` | `toolsSettings.shell.allowedCommands` / `deniedCommands` |
| `permissions` (WebFetch domains) | `toolsSettings.web_fetch.trusted` |
| `hooks.PreToolUse` | `hooks.preToolUse` |
| `hooks.PostToolUse` | `hooks.postToolUse` |
| `hooks.Stop` | `hooks.stop` |
| `mcpServers` (via plugins) | `mcpServers` |
| `model` | `model` |

Note: Kiro's UI preferences (theme, keybindings, etc.) are stored in `~/.kiro/settings/cli.json` and managed separately via `kiro-cli settings`.
