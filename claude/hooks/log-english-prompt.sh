#!/bin/sh
# Log user prompts for English review (filtered by length, excludes slash commands)

LOG_FILE="$HOME/.claude/english-prompts.log"
DEBUG_FILE="$HOME/.claude/english-prompts-debug.log"

INPUT=$(cat)

# Debug: always log raw input
echo "$(date +%Y-%m-%dT%H:%M) | $INPUT" >> "$DEBUG_FILE"

PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)

# No prompt found — approve and exit
if [ -z "$PROMPT" ]; then
  exit 0
fi

LEN=${#PROMPT}

# Filter: 20-300 chars, not a slash command
if [ "$LEN" -ge 20 ] && [ "$LEN" -le 300 ] && [ "$(echo "$PROMPT" | cut -c1)" != "/" ]; then
  echo "$(date +%Y-%m-%dT%H:%M) | $PROMPT" >> "$LOG_FILE"
fi

exit 0
