#!/bin/zsh
# cleanup-merged-worktrees.sh — merge된 PR의 git worktree를 자동 정리
#
# 안전 규칙 (보수적):
#   - PR 상태가 MERGED인 브랜치의 worktree만 제거
#   - locked worktree 스킵
#   - detached HEAD (PR 리뷰 체크아웃 등) 스킵
#   - 추적 파일에 수정이 있으면 스킵 (untracked-only는 제거 허용)
#   - 브랜치 자체는 삭제하지 않음 (커밋 복구 가능)
#
# 사용: cleanup-merged-worktrees.sh [--dry-run]
set -u

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

WORKSPACE="$HOME/Workspace"
LOG_DIR="$HOME/.local/state"
LOG="$LOG_DIR/worktree-cleanup.log"
DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

mkdir -p "$LOG_DIR"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"
}

command -v gh >/dev/null || { log "ERROR: gh not found"; exit 1; }
gh auth status >/dev/null 2>&1 || { log "ERROR: gh not authenticated"; exit 1; }

log "=== run start (dry_run=$DRY_RUN) ==="

typeset -A seen_repos  # git-common-dir 기준 dedupe (worktree 체크아웃 중복 방지)
removed_count=0

for repo in "$WORKSPACE"/*(N/); do
  [[ -e "$repo/.git" ]] || continue
  # --path-format=absolute 필수: 기본은 상대경로(.git)라 CWD 기준으로 오판됨
  common_dir=$(git -C "$repo" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || continue
  git_dir=$(git -C "$repo" rev-parse --path-format=absolute --git-dir 2>/dev/null) || continue
  # linked worktree 엔트리는 스킵 (main repo 순회 때 처리됨) — 자기 자신 제거로 인한 cd 실패 방지
  [[ "$git_dir" != "$common_dir" ]] && continue
  [[ -n "${seen_repos[$common_dir]:-}" ]] && continue
  seen_repos[$common_dir]=1

  main_wt=$(git -C "$repo" worktree list --porcelain | head -1 | sed 's/^worktree //')

  # porcelain 블록 파싱: 경로/브랜치/locked/detached (끝에 빈 줄 보장해 마지막 블록 처리)
  wt_path="" wt_branch="" wt_locked=0 wt_detached=0
  { git -C "$repo" worktree list --porcelain; echo; } | while IFS= read -r line; do
    case "$line" in
      worktree\ *) wt_path="${line#worktree }" ;;
      branch\ *)   wt_branch="${${line#branch }#refs/heads/}" ;;
      locked*)     wt_locked=1 ;;
      detached)    wt_detached=1 ;;
      "")
        if [[ -n "$wt_path" && "$wt_path" != "$main_wt" && $wt_locked -eq 0 && $wt_detached -eq 0 && -n "$wt_branch" && -d "$wt_path" ]]; then
          # 추적 파일 수정 여부 (untracked ??는 허용)
          if git -C "$wt_path" status --porcelain 2>/dev/null | grep -qv '^??'; then
            log "SKIP (dirty tracked files): $wt_path [$wt_branch]"
          else
            pr_state=$(cd "$repo" && gh pr list --head "$wt_branch" --state all --limit 1 --json state --jq '.[0].state // "NO_PR"' 2>/dev/null)
            if [[ "$pr_state" == "MERGED" ]]; then
              if [[ $DRY_RUN -eq 1 ]]; then
                log "DRY-RUN would remove: $wt_path [$wt_branch]"
              else
                if git -C "$repo" worktree remove --force "$wt_path" 2>>"$LOG"; then
                  log "REMOVED: $wt_path [$wt_branch]"
                  (( removed_count++ ))
                else
                  log "FAILED to remove: $wt_path [$wt_branch]"
                fi
              fi
            fi
          fi
        fi
        wt_path="" wt_branch="" wt_locked=0 wt_detached=0
        ;;
    esac
  done

  [[ $DRY_RUN -eq 0 ]] && git -C "$repo" worktree prune 2>>"$LOG"
done

log "=== run end ==="
