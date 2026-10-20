# GenAI

## Required

- [Claude Code \- Anthropic](https://docs.anthropic.com/en/docs/claude-code)
- [Codex CLI \- OpenAI](https://developers.openai.com/codex/cli) (optional, only when using `-a codex`)
- [apm \- Agent Package Manager](https://microsoft.github.io/apm/) (installed via `mise install`)

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

## ast-grep rules

`genai/ast-grep/` holds custom [ast-grep](https://ast-grep.github.io/) rules for what ruff, shellcheck and the other linters do not check:

| Rule | Language | Severity | Detects |
|---|---|---|---|
| `sh-no-recursive-rm` | Bash | error | `rm -r` / `rm -rf`, to be replaced with `trash` |
| `sh-no-destructive-git` | Bash | error | `git checkout` / `restore` / `clean` / `reset --hard` / `branch -D` / `push --force` |
| `sh-no-hardcoded-home-path` | Bash | warning | Paths under `/Users/<name>/` or `/home/<name>/` |
| `py-no-hardcoded-home-path` | Python | warning | The same paths outside tests |
| `yaml-no-hardcoded-home-path` | YAML | warning | The same paths, including workflow `run:` blocks |

The hooks pass `genai/ast-grep/sgconfig.yml` with `--config`, so nothing is linked into the agent's config directory, and a project's own `sgconfig.yml` takes its place.
The post-edit hook reports every finding to the agent, and the pre-commit hook blocks the commit only on error-level findings.

```bash
ast-grep test -c genai/ast-grep/sgconfig.yml --skip-snapshot-tests
```

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

Note that Codex does not support custom status line commands (only the built-in items selected in `[tui]` are shown), so `statusline/render.sh` is intentionally not wired up for Codex.

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
