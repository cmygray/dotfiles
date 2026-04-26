#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: session_delta_handoff.sh [options]

Options:
  --session-id <id>      Session ID (default: $CODEX_THREAD_ID)
  --since-ts <seconds>   Use explicit epoch-seconds anchor instead of text marker
  --anchor-text <regex>  Anchor regex (default: eject|이젝트)
  --no-copy              Do not try clipboard copy
  --out <path>           Output file path
  -h, --help             Show help
EOF
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing required command: $1" >&2
    exit 1
  fi
}

fmt_ts() {
  local ts="$1"
  if date -r 0 '+%Y-%m-%d %H:%M:%S %Z' >/dev/null 2>&1; then
    date -r "$ts" '+%Y-%m-%d %H:%M:%S %Z'
  else
    date -d "@$ts" '+%Y-%m-%d %H:%M:%S %Z'
  fi
}

sanitize_text() {
  printf '%s' "$1" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//'
}

copy_to_clipboard() {
  local content="$1"
  if command -v pbcopy >/dev/null 2>&1; then
    printf '%s' "$content" | pbcopy
    echo "pbcopy"
    return 0
  fi
  if command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$content" | wl-copy
    echo "wl-copy"
    return 0
  fi
  if command -v xclip >/dev/null 2>&1; then
    printf '%s' "$content" | xclip -selection clipboard
    echo "xclip"
    return 0
  fi
  return 1
}

SESSION_ID="${CODEX_THREAD_ID:-}"
SINCE_TS=""
ANCHOR_RE='eject|이젝트'
TRY_COPY=1
OUT_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session-id)
      SESSION_ID="${2:-}"
      shift 2
      ;;
    --since-ts)
      SINCE_TS="${2:-}"
      shift 2
      ;;
    --anchor-text)
      ANCHOR_RE="${2:-}"
      shift 2
      ;;
    --no-copy)
      TRY_COPY=0
      shift
      ;;
    --out)
      OUT_PATH="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$SESSION_ID" ]]; then
  echo "session id is required (pass --session-id or set CODEX_THREAD_ID)" >&2
  exit 1
fi

require_cmd jq

HISTORY_FILE="${HOME}/.codex/history.jsonl"
if [[ ! -f "$HISTORY_FILE" ]]; then
  echo "history file not found: $HISTORY_FILE" >&2
  exit 1
fi

if [[ -n "$SINCE_TS" ]]; then
  if ! [[ "$SINCE_TS" =~ ^[0-9]+$ ]]; then
    echo "--since-ts must be epoch seconds (integer)" >&2
    exit 1
  fi
  ANCHOR_TS="$SINCE_TS"
  ANCHOR_DESC="explicit timestamp"
else
  ANCHOR_TS="$(jq -sr --arg sid "$SESSION_ID" --arg re "$ANCHOR_RE" '
    map(
      select(
        .session_id == $sid
        and (.text | type == "string")
        and (.text | test($re; "i"))
      )
      | (try (.ts | tonumber) catch 0)
    )
    | max // 0
  ' "$HISTORY_FILE")"
  ANCHOR_DESC="latest marker /$ANCHOR_RE/"
fi

mapfile -t DELTA_ROWS < <(jq -c --arg sid "$SESSION_ID" --arg anchor "$ANCHOR_TS" '
  select(
    .session_id == $sid
    and (.text | type == "string")
    and ((try (.ts | tonumber) catch 0) > ($anchor | tonumber))
  )
  | {ts: (try (.ts | tonumber) catch 0), text}
' "$HISTORY_FILE")

if [[ -z "$OUT_PATH" ]]; then
  OUT_PATH="$(pwd)/session-delta-${SESSION_ID}-$(date +%Y%m%d-%H%M%S).txt"
fi

NOW_STR="$(fmt_ts "$(date +%s)")"
if [[ "$ANCHOR_TS" -gt 0 ]]; then
  ANCHOR_STR="$(fmt_ts "$ANCHOR_TS")"
else
  ANCHOR_STR="없음 (세션 전체 기준)"
fi

GIT_BRANCH="-"
GIT_COMMITS="-"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  GIT_BRANCH="$(git branch --show-current 2>/dev/null || echo '-')"
  GIT_COMMITS="$(git log --oneline -n 2 2>/dev/null || echo '-')"
fi

{
  echo "세션 재개용 delta handoff"
  echo ""
  echo "- 생성 시각: $NOW_STR"
  echo "- session_id: $SESSION_ID"
  echo "- anchor: $ANCHOR_DESC"
  echo "- anchor_ts: $ANCHOR_STR"
  echo "- delta_count: ${#DELTA_ROWS[@]}"
  echo ""
  echo "새 사용자 메시지:"
  if [[ ${#DELTA_ROWS[@]} -eq 0 ]]; then
    echo "- (없음) 마지막 anchor 이후 신규 항목이 없습니다."
  else
    for row in "${DELTA_ROWS[@]}"; do
      ts="$(jq -r '.ts' <<<"$row")"
      text="$(jq -r '.text' <<<"$row")"
      text="$(sanitize_text "$text")"
      echo "- [$(fmt_ts "$ts")] $text"
    done
  fi
  echo ""
  echo "현재 git 컨텍스트:"
  echo "- branch: $GIT_BRANCH"
  echo "- recent commits:"
  if [[ "$GIT_COMMITS" == "-" ]]; then
    echo "  - -"
  else
    while IFS= read -r line; do
      echo "  - $line"
    done <<<"$GIT_COMMITS"
  fi
} >"$OUT_PATH"

RESULT="$(cat "$OUT_PATH")"

CLIP_STATUS="not requested"
if [[ "$TRY_COPY" -eq 1 ]]; then
  if TOOL="$(copy_to_clipboard "$RESULT")"; then
    CLIP_STATUS="copied via $TOOL"
  else
    CLIP_STATUS="copy failed (no supported clipboard command)"
  fi
fi

printf '%s\n' "$RESULT"
echo "" >&2
echo "output_file: $OUT_PATH" >&2
echo "clipboard: $CLIP_STATUS" >&2
