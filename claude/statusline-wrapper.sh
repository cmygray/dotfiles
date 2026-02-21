#!/usr/bin/env bash
# Enhanced statusline wrapper for Claude Code
# Displays: model | path | branch | context usage

set -euo pipefail

# Capture stdin
input=$(cat)

# Get model info from ccusage (first segment only, before first pipe)
model_info=$(echo "$input" | bun x ccusage statusline --no-offline 2>/dev/null | cut -d'|' -f1 | xargs || echo "🤖 Claude")

# Calculate context window usage (current conversation only)
usage=$(echo "$input" | jq '.context_window.current_usage' 2>/dev/null)
context_info=""
if [ "$usage" != "null" ] && [ -n "$usage" ]; then
    current=$(echo "$usage" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens' 2>/dev/null)
    size=$(echo "$input" | jq '.context_window.context_window_size' 2>/dev/null)
    if [ -n "$current" ] && [ -n "$size" ] && [ "$size" != "null" ] && [ "$size" -gt 0 ]; then
        pct=$((current * 100 / size))
        context_info="🧠 ${pct}%"
    fi
fi

# Extract workspace info from JSON
cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty' 2>/dev/null || echo "")

# Use full directory path with ~ abbreviation for home
display_path="${cwd:-$(pwd)}"
display_path="${display_path/#$HOME/\~}"

# Get git branch and dirty status
branch=$(git -C "${cwd:-$(pwd)}" -c core.useBuiltinFSMonitor=false branch --show-current 2>/dev/null || echo "")
dirty=""
if [ -n "$branch" ] && [ -n "$(git -C "${cwd:-$(pwd)}" status --porcelain 2>/dev/null)" ]; then
    dirty="*"
fi

# Assemble single-line output
if [ -n "$branch" ] && [ -n "$context_info" ]; then
    echo "${model_info} | 📁 ${display_path} | 🌿 ${branch}${dirty} | ${context_info}"
elif [ -n "$branch" ]; then
    echo "${model_info} | 📁 ${display_path} | 🌿 ${branch}${dirty}"
elif [ -n "$context_info" ]; then
    echo "${model_info} | 📁 ${display_path} | ${context_info}"
else
    echo "${model_info} | 📁 ${display_path}"
fi
