#!/bin/sh
# Strip "worktree-" prefix from branch name to match repo conventions.
# Always exits 0 (non-blocking).

git_dir="$(git rev-parse --git-dir 2>/dev/null)" || exit 0
case "$git_dir" in
  */.git/worktrees/*) ;;
  *) exit 0 ;;
esac

branch="$(git branch --show-current 2>/dev/null)"
case "$branch" in
  worktree-*)
    target="${branch#worktree-}"
    if ! git show-ref --verify --quiet "refs/heads/$target" 2>/dev/null; then
      git branch -m "$target" 2>/dev/null
    fi
    ;;
esac

exit 0
