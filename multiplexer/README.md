# Multiplexer

## Required

- [herdr](https://herdr.dev)

## Setup herdr

1. Execute multiplexer setup script with the multiplexer option set to herdr.

```bash
./multiplexer/setup.sh -m herdr
```

This links:

- `multiplexer/config.toml` → `~/.config/herdr/config.toml` (symlinked)

herdr saves settings changes through the link, so they show up in `git diff`.
