#!/usr/bin/env bash
# Jump to the next Claude notification target
# Proven: wezterm cli activate-tab, zellij action go-to-tab
set -euo pipefail
export PATH="/opt/homebrew/bin:$PATH"

queue_file="$HOME/.claude/notification-queue.jsonl"
if [[ ! -f "$queue_file" ]] || [[ ! -s "$queue_file" ]]; then
  exit 0
fi

# Pop the first entry
entry=$(head -1 "$queue_file")
tail -n +2 "$queue_file" > "$queue_file.tmp" && mv "$queue_file.tmp" "$queue_file"

wez_tab_id=$(echo "$entry" | jq -r '.wez_tab_id // ""')
zj_session=$(echo "$entry" | jq -r '.zj_session // ""')
zj_pane_id=$(echo "$entry" | jq -r '.zj_pane_id // ""')
zj_tab_index=$(echo "$entry" | jq -r '.zj_tab_index // ""')

# WezTerm: switch tab
symlink="$HOME/.local/share/wezterm/default-org.wezfurlong.wezterm"
if [[ -n "$wez_tab_id" && -S "$symlink" ]]; then
  WEZTERM_UNIX_SOCKET="$symlink" wezterm cli activate-tab --tab-id "$wez_tab_id" 2>/dev/null || true
fi

# Zellij: focus by pane ID (plugin) or tab index (fallback)
if [[ -n "$zj_session" ]]; then
  if [[ -n "$zj_pane_id" ]]; then
    plugin="file:$HOME/dotfiles/zellij/plugins/zellij-focus/target/wasm32-wasip1/release/zellij-focus.wasm"
    if [[ -f "${plugin#file:}" ]]; then
      timeout 2 zellij -s "$zj_session" pipe --plugin "$plugin" --name focus -- "$zj_pane_id" 2>/dev/null || true
    fi
  elif [[ -n "$zj_tab_index" ]]; then
    zellij --session "$zj_session" action go-to-tab "$zj_tab_index" 2>/dev/null || true
  fi
fi

# Activate WezTerm
osascript -e 'tell application "WezTerm" to activate'
