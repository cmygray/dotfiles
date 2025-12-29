#!/usr/bin/env bash
# Notification wrapper for Claude Code
# Extracts message from JSON input and sends via noti

set -euo pipefail

# Read JSON from stdin
input=$(cat)

# Extract message from JSON
message=$(echo "$input" | jq -r '.message // "Claude Code notification"' 2>/dev/null || echo "Claude Code notification")

# Send notification
noti -t 'Claude Code' -m "$message"
