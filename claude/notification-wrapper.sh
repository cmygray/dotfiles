#!/usr/bin/env bash
# Notification wrapper for Claude Code
# Shows the last user message as context so you know which session completed
# Saves focus target for jump-to-notification.sh

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
    last_user_msg=$(tail -100 "$jsonl_file" \
      | jq -r 'select(.type == "user" and .userType == "external" and (.message.content | type) == "string") | .message.content' 2>/dev/null \
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

# Save focus target to queue
# WezTerm: resolve tab ID from current pane
wez_tab_id=""
symlink="$HOME/.local/share/wezterm/default-org.wezfurlong.wezterm"
if [[ -S "$symlink" ]]; then
  wez_tab_id=$(WEZTERM_UNIX_SOCKET="$symlink" wezterm cli list --format json 2>/dev/null \
    | jq -r --arg pane "${WEZTERM_PANE:-}" '.[] | select(.pane_id == ($pane | tonumber)) | .tab_id' 2>/dev/null || echo "")
fi

# Zellij: resolve tab index from cwd
zj_session="${ZELLIJ_SESSION_NAME:-}"
zj_tab_index=""
if [[ -n "$zj_session" && -n "$cwd_segment" ]]; then
  idx=0
  while IFS= read -r tab_name; do
    idx=$((idx + 1))
    if [[ "$cwd_segment" == *"$tab_name"* || "$tab_name" == *"$cwd_segment"* ]]; then
      zj_tab_index=$idx
      break
    fi
  done < <(zellij --session "$zj_session" action query-tab-names 2>/dev/null)
fi

mkdir -p ~/.claude
jq -cn \
  --arg wez_tab_id "$wez_tab_id" \
  --arg zj_session "$zj_session" \
  --arg zj_tab_index "$zj_tab_index" \
  --arg title "$title" \
  '{wez_tab_id: $wez_tab_id, zj_session: $zj_session, zj_tab_index: $zj_tab_index, title: $title}' \
  >> "$HOME/.claude/notification-queue.jsonl"

noti -t "$title" -m "$body"
