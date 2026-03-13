#!/bin/sh
# Sync zellij pane name with worktree branch + issue + PR info.
# Format: "branch-name [#issue] [PR#number]"
# Always exits 0 (non-blocking).

[ -z "$ZELLIJ" ] && exit 0

git_dir="$(git rev-parse --git-dir 2>/dev/null)" || exit 0
case "$git_dir" in
  */.git/worktrees/*) ;;
  *) exit 0 ;;
esac

branch="$(git branch --show-current 2>/dev/null)"
[ -z "$branch" ] && exit 0

# Cache: keyed by branch, valid for 5 minutes
cache_dir="/tmp/zellij-pane-cache"
mkdir -p "$cache_dir"
cache_key="$(printf '%s' "$branch" | shasum | cut -d' ' -f1)"
cache_file="$cache_dir/$cache_key"

if [ -f "$cache_file" ]; then
  cache_age=$(( $(date +%s) - $(stat -f%m "$cache_file") ))
  if [ "$cache_age" -lt 300 ]; then
    zellij action rename-pane "$(cat "$cache_file")" 2>/dev/null
    exit 0
  fi
fi

# Set basic name immediately (fast path)
zellij action rename-pane "$branch" 2>/dev/null

# Fetch enriched name in background, then update pane + cache
(
  pane_name="$branch"

  # Extract issue number from branch name
  issue_ref="$(printf '%s' "$branch" | grep -oE '#[0-9]+' | head -1)"
  if [ -z "$issue_ref" ]; then
    issue_ref="$(printf '%s' "$branch" | grep -oE '[A-Z]+-[0-9]+' | head -1)"
  fi

  # Find PR for this branch
  pr_num="$(gh pr list --head "$branch" --json number -q '.[0].number' 2>/dev/null)"

  # If we have a PR but no issue, try parsing from PR body
  if [ -n "$pr_num" ] && [ -z "$issue_ref" ]; then
    body="$(gh pr view "$pr_num" --json body -q '.body' 2>/dev/null)"
    issue_ref="$(printf '%s' "$body" | grep -oiE '(close[sd]?|fix(e[sd])?|resolve[sd]?)\s+#[0-9]+' | grep -oE '#[0-9]+' | head -1)"
  fi

  [ -n "$issue_ref" ] && pane_name="$pane_name $issue_ref"
  [ -n "$pr_num" ] && pane_name="$pane_name PR#$pr_num"

  printf '%s' "$pane_name" > "$cache_file"
  zellij action rename-pane "$pane_name" 2>/dev/null
) &

exit 0
