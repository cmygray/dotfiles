#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: session_eject.sh <session-id>

Recover wide context for a session ID from:
- ~/.codex/history.jsonl
- ~/.claude/history.jsonl
- ~/.claude/sessions/*.json
- ~/.claude/projects/**/<session-id>.jsonl
EOF
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing required command: $1" >&2
    exit 1
  fi
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 1
fi

require_cmd jq
require_cmd rg

SESSION_ID="$1"
CODEX_DIR="${HOME}/.codex"
CLAUDE_DIR="${HOME}/.claude"

CODEX_HISTORY="${CODEX_DIR}/history.jsonl"
CLAUDE_HISTORY="${CLAUDE_DIR}/history.jsonl"
CLAUDE_SESSION_META="$(rg -l "\"sessionId\":\"${SESSION_ID}\"" "${CLAUDE_DIR}/sessions" 2>/dev/null | head -n 1 || true)"
CLAUDE_TRANSCRIPT="$(find "${CLAUDE_DIR}/projects" -type f -name "${SESSION_ID}.jsonl" 2>/dev/null | head -n 1 || true)"

print_section() {
  printf '\n== %s ==\n' "$1"
}

iso_from_ms() {
  local ms="$1"
  if [[ -z "${ms}" || "${ms}" == "null" ]]; then
    echo "-"
    return
  fi

  if date -r 0 '+%Y-%m-%dT%H:%M:%S%z' >/dev/null 2>&1; then
    date -r "$((ms / 1000))" '+%Y-%m-%d %H:%M:%S %Z'
  else
    date -d "@$((ms / 1000))" '+%Y-%m-%d %H:%M:%S %Z'
  fi
}

FOUND=0

if [[ -f "${CODEX_HISTORY}" ]] && rg -q "\"session_id\":\"${SESSION_ID}\"" "${CODEX_HISTORY}" 2>/dev/null; then
  FOUND=1
  print_section "Codex History"
  jq -r --arg sid "${SESSION_ID}" '
    select(.session_id == $sid)
    | [.ts, .text]
    | @tsv
  ' "${CODEX_HISTORY}" | while IFS=$'\t' read -r ts text; do
    if [[ -n "${ts}" ]]; then
      if date -r 0 '+%Y-%m-%dT%H:%M:%S%z' >/dev/null 2>&1; then
        stamp="$(date -r "${ts}" '+%Y-%m-%d %H:%M:%S %Z')"
      else
        stamp="$(date -d "@${ts}" '+%Y-%m-%d %H:%M:%S %Z')"
      fi
    else
      stamp="-"
    fi
    printf '%s\t%s\n' "${stamp}" "${text}"
  done
fi

if [[ -n "${CLAUDE_SESSION_META}" || -n "${CLAUDE_TRANSCRIPT}" ]] || [[ -f "${CLAUDE_HISTORY}" ]] && rg -q "\"sessionId\":\"${SESSION_ID}\"" "${CLAUDE_HISTORY}" 2>/dev/null; then
  FOUND=1
  print_section "Claude Session"
  if [[ -n "${CLAUDE_SESSION_META}" ]]; then
    jq -r '
      "session_id: \(.sessionId)",
      "name: \(.name // "-")",
      "cwd: \(.cwd // "-")",
      "kind: \(.kind // "-")",
      "entrypoint: \(.entrypoint // "-")",
      "started_at_ms: \(.startedAt // "-")"
    ' "${CLAUDE_SESSION_META}"
    STARTED_AT_MS="$(jq -r '.startedAt // empty' "${CLAUDE_SESSION_META}")"
    if [[ -n "${STARTED_AT_MS}" ]]; then
      echo "started_at_local: $(iso_from_ms "${STARTED_AT_MS}")"
    fi
    echo "session_meta: ${CLAUDE_SESSION_META}"
  else
    echo "session_meta: -"
  fi

  echo "transcript: ${CLAUDE_TRANSCRIPT:-"-"}"

  if [[ -n "${CLAUDE_TRANSCRIPT}" ]]; then
    print_section "Claude Transcript"
    echo "bytes: $(wc -c < "${CLAUDE_TRANSCRIPT}" | tr -d ' ')"
    echo "lines: $(wc -l < "${CLAUDE_TRANSCRIPT}" | tr -d ' ')"

    print_section "Timeline"
    jq -r '
      select(.type == "user" and .message.role == "user")
      | select((.message.content | type) == "string")
      | select(.message.content | startswith("<") | not)
      | [.timestamp, .message.content]
      | @tsv
    ' "${CLAUDE_TRANSCRIPT}" | sed -n '1,60p'

    print_section "Branches"
    jq -r '
      select(.gitBranch != null)
      | [.timestamp, .gitBranch]
      | @tsv
    ' "${CLAUDE_TRANSCRIPT}" | awk '!seen[$2]++'

    print_section "Touched Files"
    jq -r '
      select((.toolUseResult | type) == "object" and .toolUseResult.filePath != null)
      | .toolUseResult.filePath
    ' "${CLAUDE_TRANSCRIPT}" | sort | uniq -c | sort -nr | sed -n '1,25p'

    print_section "Latest User Messages"
    jq -r '
      select(.type == "user" and .message.role == "user")
      | select((.message.content | type) == "string")
      | select(.message.content | startswith("<") | not)
      | [.timestamp, .message.content]
      | @tsv
    ' "${CLAUDE_TRANSCRIPT}" | tail -n 12

    print_section "Latest Assistant Messages"
    jq -r '
      select(.type == "assistant" and .message.role == "assistant")
      | [.timestamp, ([.message.content[]? | select(.type == "text") | .text] | join("\n"))]
      | @tsv
    ' "${CLAUDE_TRANSCRIPT}" | awk -F '\t' 'length($2) > 0' | tail -n 8
  fi

  if [[ -f "${CLAUDE_HISTORY}" ]]; then
    print_section "Claude History Index"
    rg -n "\"sessionId\":\"${SESSION_ID}\"" "${CLAUDE_HISTORY}" 2>/dev/null | sed -n '1,80p'
  fi
fi

if [[ "${FOUND}" -eq 0 ]]; then
  echo "session not found: ${SESSION_ID}" >&2
  exit 1
fi
