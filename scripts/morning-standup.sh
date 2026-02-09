#!/usr/bin/env bash
# morning-standup: 오전 출근 시 실행 — 직전 워킹데이의 미완료 작업 + 액션아이템
# Usage: morning-standup

set -euo pipefail

TODAY="$(date +%Y-%m-%d)"
GH_USER="$(gh api user --jq '.login' 2>/dev/null || echo '')"
CLAUDE_DIR="$HOME/.claude"

# Colors
BOLD='\033[1m'
DIM='\033[2m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
MAGENTA='\033[35m'
RED='\033[31m'
RESET='\033[0m'

# ── Find last working day from history.jsonl ────────────
LAST_WORKDAY=$(python3 -c "
import json
from datetime import datetime, timezone, timedelta
from pathlib import Path

kst = timezone(timedelta(hours=9))
today = datetime.strptime('${TODAY}', '%Y-%m-%d').replace(tzinfo=kst).date()

history = Path.home() / '.claude' / 'history.jsonl'
if not history.exists():
    exit(1)

days = set()
with open(history) as f:
    for line in f:
        e = json.loads(line)
        ts = e.get('timestamp', 0)
        dt = datetime.fromtimestamp(ts / 1000, tz=kst).date()
        if dt < today:
            days.add(dt)

if days:
    print(max(days).isoformat())
" 2>/dev/null)

if [[ -z "$LAST_WORKDAY" ]]; then
  echo -e "${DIM}이전 작업 기록 없음${RESET}"
  exit 0
fi

echo -e "${BOLD}☀️ Morning Standup — ${TODAY}${RESET}"
echo -e "${DIM}직전 워킹데이: ${LAST_WORKDAY}${RESET}"
echo ""

# ── Open PRs that need attention ────────────────────────
if [[ -n "$GH_USER" ]]; then
  echo -e "${BOLD}${CYAN}▸ 내 Open PRs (리뷰 대기 중)${RESET}"
  echo ""
  gh search prs --author="$GH_USER" --state=open --json repository,number,title,url,isDraft,updatedAt \
    --jq '.[] | "  \(if .isDraft then "◐" else "●" end) \(.repository.nameWithOwner)#\(.number) \(.title)\n    \(.url)"' 2>/dev/null | head -20 || true
  echo ""
fi

# ── Claude Sessions: unfinished work ───────────────────
echo -e "${BOLD}${CYAN}▸ 미완료 작업 + 액션아이템${RESET}"
echo ""

SESSION_RAW=$(python3 -c "
import json
from datetime import datetime, timezone, timedelta
from pathlib import Path
from collections import OrderedDict

kst = timezone(timedelta(hours=9))
target = datetime.strptime('${LAST_WORKDAY}', '%Y-%m-%d').replace(tzinfo=kst)
day_start_ms = int(target.timestamp() * 1000)
day_end_ms = day_start_ms + 86400000

history = Path.home() / '.claude' / 'history.jsonl'
projects = OrderedDict()
with open(history) as f:
    for line in f:
        e = json.loads(line)
        ts = e.get('timestamp', 0)
        if day_start_ms <= ts < day_end_ms:
            proj = e.get('project', '?')
            display = e.get('display', '').strip()
            if not display or display.startswith('/clear'):
                continue
            if proj not in projects:
                projects[proj] = []
            projects[proj].append(display[:120])

# session resume IDs
claude_dir = Path.home() / '.claude' / 'projects'
session_map = {}
if claude_dir.exists():
    for idx_file in claude_dir.rglob('sessions-index.json'):
        try:
            with open(idx_file) as f:
                data = json.load(f)
            for entry in data.get('entries', []):
                pp = entry.get('projectPath', '')
                mod = entry.get('modified', '')
                if mod:
                    mod_dt = datetime.fromisoformat(mod.replace('Z', '+00:00')).astimezone(kst)
                    if mod_dt.date() == target.date():
                        if pp not in session_map:
                            session_map[pp] = []
                        session_map[pp].append(entry)
        except Exception:
            pass

import sys
result = []
for proj, prompts in projects.items():
    short = proj.replace(str(Path.home()), '~')
    sessions = session_map.get(proj, [])
    resume_ids = [s['sessionId'] for s in sessions if 'sessionId' in s]
    result.append({
        'project': short,
        'prompt_count': len(prompts),
        'first_prompts': prompts[:5],
        'last_prompts': prompts[-5:],
        'resume_ids': resume_ids,
    })

json.dump(result, sys.stdout, ensure_ascii=False)
" 2>/dev/null)

if [[ -z "$SESSION_RAW" || "$SESSION_RAW" == "[]" ]]; then
  echo -e "  ${DIM}(직전 워킹데이 Claude 세션 없음)${RESET}"
else
  echo "$SESSION_RAW" | claude -p --model haiku \
    "아래 JSON은 직전 워킹데이(${LAST_WORKDAY})에 프로젝트별로 Claude에게 보낸 프롬프트 목록이다.
first_prompts는 세션 초반, last_prompts는 세션 말미의 프롬프트다.

오늘 아침 출근해서 이어할 작업을 파악하는 게 목적이다.
각 프로젝트별로:
1. 한 줄 요약 (무슨 작업이었는지)
2. status: done 또는 in-progress (last_prompts 기반 추론)
3. action: in-progress인 경우 구체적인 다음 액션, done이면 생략

done인 프로젝트는 간략히, in-progress인 프로젝트는 상세히 써줘.

출력 포맷 (plain text, 마크다운/코드블록 사용 금지):
  [project] — 한줄 요약
    status: done
또는
  [project] — 한줄 요약
    status: in-progress
    action: 구체적 다음 액션
    resume: claude -r <session-id> (resume_ids가 있을 때만)

resume_ids가 비어있으면 resume 줄은 생략.
설명이나 머리말 없이 바로 출력만." 2>/dev/null | \
  sed -E \
    -e 's|^(~/[^ ]+)|\\033[1m\1\\033[0m|' \
    -e 's/^    status: done/    \\033[32m✔ done\\033[0m/' \
    -e 's/^    status: in-progress/    \\033[33m⏳ in-progress\\033[0m/' \
    -e 's/^    action: (.+)/    \\033[33m→ \1\\033[0m/' \
    -e 's/^    resume: (.+)/    \\033[36m↪ \1\\033[0m/' | \
  while IFS= read -r line; do echo -e "$line"; done || \
  python3 -c "
import json, sys
data = json.loads('''${SESSION_RAW}''')
for item in data:
    proj = item['project']
    prompts = item.get('last_prompts', [])
    print(f'  \033[1m{proj}\033[0m')
    for p in prompts[-3:]:
        line = p.split(chr(10))[0][:80]
        print(f'    \033[2m{line}\033[0m')
    print()
" 2>/dev/null
fi

echo ""
echo -e "${DIM}Tip: claude -r (interactive picker) 또는 claude -r <session-id>${RESET}"
