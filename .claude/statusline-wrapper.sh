#!/usr/bin/env bash
# Enhanced statusline wrapper for Claude Code
# Combines ccusage output with current path, git branch, and context window usage

set -euo pipefail

# Capture stdin
input=$(cat)

# Get ccusage output (preserving original flags)
ccusage_output=$(echo "$input" | bun x ccusage statusline --no-offline --visual-burn-rate emoji 2>/dev/null || echo "🤖 Claude")

# Calculate context window usage
usage=$(echo "$input" | jq '.context_window.current_usage' 2>/dev/null)
context_info=""
if [ "$usage" != "null" ] && [ -n "$usage" ]; then
    current=$(echo "$usage" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens' 2>/dev/null)
    size=$(echo "$input" | jq '.context_window.context_window_size' 2>/dev/null)
    if [ -n "$current" ] && [ -n "$size" ] && [ "$size" != "null" ] && [ "$size" -gt 0 ]; then
        pct=$((current * 100 / size))
        context_info=" | 🧠 ${current} (${pct}%)"
    fi
fi

# Extract workspace info from JSON
cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty' 2>/dev/null || echo "")
project_dir=$(echo "$input" | jq -r '.workspace.project_dir // empty' 2>/dev/null || echo "")

# Use full directory path with ~ abbreviation for home
display_path="${cwd:-$(pwd)}"
display_path="${display_path/#$HOME/\~}"

# Get git branch (skip optional locks as per CLAUDE.md)
branch=$(git -C "${cwd:-$(pwd)}" -c core.useBuiltinFSMonitor=false branch --show-current 2>/dev/null || echo "")

# Assemble final output with newline separation
echo "${ccusage_output}${context_info}"
if [ -n "$branch" ]; then
    echo "📁 $display_path | 🌿 $branch"
else
    echo "📁 $display_path"
fi
