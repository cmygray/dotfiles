#!/bin/zsh -l
# Keep a Claude Code Remote Control server running in tmux session "claude-rc".
# Machine-specific name: ~/.config/claude-rc/name (e.g. mac-studio, work). Missing → no-op.
# Spawned sessions inherit this env, so start via an interactive zsh to load ~/.zshrc (PATH, mise).
# DISABLE_AUTO_UPDATE: oh-my-zsh update prompt would otherwise block startup.
NAME_FILE="$HOME/.config/claude-rc/name"
[ -s "$NAME_FILE" ] || exit 0
RC_NAME=$(head -1 "$NAME_FILE")
RC_DIR="$HOME/src"
LOG="$HOME/Library/Logs/claude-rc.log"

# pgrep은 실행 컨텍스트에 따라 프로세스를 못 보는 경우가 있어 ps로 확인
ps -axo command= | grep -qE "^(/[^ ]*/)?claude remote-control --name $RC_NAME( |\$)" && exit 0
TMUX_BIN=/opt/homebrew/bin/tmux
$TMUX_BIN kill-session -t claude-rc 2>/dev/null
$TMUX_BIN new-session -d -s claude-rc -c "$RC_DIR" "DISABLE_AUTO_UPDATE=true zsh -ic 'claude remote-control --name $RC_NAME --spawn same-dir'; exec zsh -i"
echo "$(date '+%F %T') started claude-rc ($RC_NAME)" >> "$LOG"
