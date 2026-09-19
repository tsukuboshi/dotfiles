---
paths:
  - "**/*.{sh,bash}"
---

# Shell Script

- リンタ: `shellcheck`
- フォーマッタ: `shfmt -w`

`shellcheck` と `shfmt` は sh / bash / dash / ksh のみ対応するため、zsh スクリプト（`.zsh`、および `#!/bin/zsh` の `.sh`）は対象外とする。
