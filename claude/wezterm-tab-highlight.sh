#!/usr/bin/env bash
set -euo pipefail
status="${1:-idle}"
printf "\033]1337;SetUserVar=%s=%s\007" \
  "claude_status" "$(printf '%s' "$status" | base64)" > /dev/tty 2>/dev/null || true
