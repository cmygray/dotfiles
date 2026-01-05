#!/usr/bin/env bash
# Notification wrapper for Claude Code
# Extracts message and cwd from JSON input and sends via noti

set -euo pipefail

# Read JSON from stdin
input=$(cat)

# Extract message from JSON
message=$(echo "$input" | jq -r '.message // "Claude Code notification"' 2>/dev/null || echo "Claude Code notification")

# Extract cwd and get the last segment (directory name)
cwd=$(echo "$input" | jq -r '.cwd // ""' 2>/dev/null || echo "")
cwd_segment=$(basename "$cwd" 2>/dev/null || echo "")

# Append cwd segment to message if available
if [[ -n "$cwd_segment" ]]; then
  message="[$cwd_segment] $message"
fi

# Send notification
noti -t 'Claude Code' -m "$message"
