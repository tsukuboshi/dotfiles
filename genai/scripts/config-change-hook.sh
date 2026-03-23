#!/bin/bash
# ConfigChange hook: log all settings changes during sessions

INPUT=$(cat)
TIMESTAMP=$(date -Iseconds)
LOG_FILE="${HOME}/.claude/audit.log"

echo "[${TIMESTAMP}] Config changed: ${INPUT}" >>"${LOG_FILE}"

exit 0
