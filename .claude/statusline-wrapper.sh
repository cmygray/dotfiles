#!/usr/bin/env bash
# Enhanced statusline wrapper for Claude Code
# Combines ccusage output with current path and git branch

set -euo pipefail

# Capture stdin
input=$(cat)

# Get ccusage output (preserving original flags)
ccusage_output=$(echo "$input" | bun x ccusage statusline --no-offline --visual-burn-rate emoji 2>/dev/null || echo "🤖 Claude")

# Extract workspace info from JSON
cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty' 2>/dev/null || echo "")
project_dir=$(echo "$input" | jq -r '.workspace.project_dir // empty' 2>/dev/null || echo "")

# Use full directory path with ~ abbreviation for home
display_path="${cwd:-$(pwd)}"
display_path="${display_path/#$HOME/\~}"

# Get git branch (skip optional locks as per CLAUDE.md)
branch=$(git -C "${cwd:-$(pwd)}" -c core.useBuiltinFSMonitor=false branch --show-current 2>/dev/null || echo "")

# Assemble final output with newline separation
echo "$ccusage_output"
if [ -n "$branch" ]; then
    echo "📁 $display_path | 🌿 $branch"
else
    echo "📁 $display_path"
fi
