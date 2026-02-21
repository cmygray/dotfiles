#!/usr/bin/env bash
# Notification wrapper for Claude Code
# Shows the last user message as context so you know which session completed

set -euo pipefail

# Read JSON from stdin
input=$(cat)

# Extract fields from JSON
message=$(echo "$input" | jq -r '.message // "Claude Code notification"' 2>/dev/null || echo "Claude Code notification")
cwd=$(echo "$input" | jq -r '.cwd // ""' 2>/dev/null || echo "")
cwd_segment=$(basename "$cwd" 2>/dev/null || echo "")
session_id=$(echo "$input" | jq -r '.session_id // ""' 2>/dev/null || echo "")

# Extract last user message from session
last_user_msg=""
if [[ -n "$session_id" ]]; then
  jsonl_file=$(find ~/.claude/projects -name "${session_id}.jsonl" -type f 2>/dev/null | head -1)
  if [[ -n "$jsonl_file" ]]; then
    # Get the last external user message, take first line, truncate to 80 chars
    last_user_msg=$(tail -100 "$jsonl_file" \
      | jq -r 'select(.type == "user" and .userType == "external") | (.message.content // .message // "")' 2>/dev/null \
      | tail -1 \
      | head -1 \
      | cut -c1-80)
  fi
fi

# Build notification title with project name
title="Claude Code"
if [[ -n "$cwd_segment" ]]; then
  title="Claude Code [${cwd_segment}]"
fi

# Use last user message as body context, fallback to default message
body="${last_user_msg:-${message}}"

noti -t "$title" -m "$body"
