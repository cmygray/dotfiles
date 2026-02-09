#!/usr/bin/env bash
# daily-briefing: 오늘의 업무 브리핑 (PRs + Claude sessions)
# Usage: daily-briefing [YYYY-MM-DD]

set -euo pipefail

DATE="${1:-$(date +%Y-%m-%d)}"
GH_USER="$(gh api user --jq '.login' 2>/dev/null || echo '')"
CLAUDE_DIR="$HOME/.claude"

# Colors
BOLD='\033[1m'
DIM='\033[2m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
MAGENTA='\033[35m'
RESET='\033[0m'

echo -e "${BOLD}📋 Daily Briefing — ${DATE}${RESET}"
echo ""

# ── GitHub PRs ──────────────────────────────────────────
if [[ -n "$GH_USER" ]]; then
  echo -e "${BOLD}${CYAN}▸ GitHub PRs${RESET}"
  echo ""

  # Opened (non-draft)
  echo -e "  ${GREEN}● Opened${RESET}"
  gh search prs --author="$GH_USER" --created="$DATE" --state=open --json repository,number,title,url,isDraft \
    --jq '.[] | select(.isDraft == false) | "    \(.repository.nameWithOwner)#\(.number) \(.title)\n    \(.url)"' 2>/dev/null || true
  echo ""

  # Draft
  echo -e "  ${YELLOW}◐ Draft${RESET}"
  gh search prs --author="$GH_USER" --created="$DATE" --state=open --json repository,number,title,url,isDraft \
    --jq '.[] | select(.isDraft == true) | "    \(.repository.nameWithOwner)#\(.number) \(.title)\n    \(.url)"' 2>/dev/null || true
  echo ""

  # Merged
  echo -e "  ${MAGENTA}✔ Merged${RESET}"
  gh search prs --author="$GH_USER" --merged="$DATE" --json repository,number,title,url \
    --jq '.[] | "    \(.repository.nameWithOwner)#\(.number) \(.title)\n    \(.url)"' 2>/dev/null || true
  echo ""
fi

# ── Claude Sessions (today) ────────────────────────────
echo -e "${BOLD}${CYAN}▸ Claude Sessions${RESET}"
echo ""

# Collect session data from history.jsonl, then summarize with claude -p
SESSION_RAW=$(python3 -c "
import json
from datetime import datetime, timezone, timedelta
from pathlib import Path
from collections import OrderedDict

kst = timezone(timedelta(hours=9))
target = datetime.strptime('${DATE}', '%Y-%m-%d').replace(tzinfo=kst)
day_start_ms = int(target.timestamp() * 1000)
day_end_ms = day_start_ms + 86400000

history = Path.home() / '.claude' / 'history.jsonl'
if not history.exists():
    exit()

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

# Match sessions from sessions-index.json for resume IDs
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

# Output structured data for claude -p summarization
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
  echo -e "  ${DIM}(오늘 Claude 세션 없음)${RESET}"
else
  # Summarize with claude -p (haiku for speed/cost)
  echo "$SESSION_RAW" | claude -p --model haiku \
    "아래 JSON은 오늘 하루 동안 프로젝트별로 Claude에게 보낸 프롬프트 목록이다.
first_prompts는 세션 초반, last_prompts는 세션 말미의 프롬프트다.

각 프로젝트별로:
1. 한 줄 요약 (무슨 작업이었는지)
2. next action (last_prompts를 기반으로 추론한 다음 할 일, 없으면 done)

출력 포맷 (plain text, 마크다운/코드블록 사용 금지):
  [project] — 한줄 요약
    next: 다음 할 일 (또는 done)
    resume: claude -r <session-id> (resume_ids가 있을 때만)

resume_ids가 비어있으면 resume 줄은 생략.
설명이나 머리말 없이 바로 출력만." 2>/dev/null | \
  # Add ANSI colors to plain text output
  sed -E \
    -e 's|^(~/[^ ]+)|\\033[1m\1\\033[0m|' \
    -e 's/^    next: (.+)/    \\033[33m→ \1\\033[0m/' \
    -e 's/^    resume: (.+)/    \\033[36m↪ \1\\033[0m/' | \
  while IFS= read -r line; do echo -e "$line"; done || \
  # Fallback: claude -p 실패 시 raw 출력
  python3 -c "
import json, sys
data = json.loads('''${SESSION_RAW}''')
for item in data:
    proj = item['project']
    count = item['prompt_count']
    prompts = item['prompts']
    resume_ids = item.get('resume_ids', [])
    print(f'  \033[1m{proj}\033[0m ({count} prompts)')
    for p in prompts[:3]:
        line = p.split(chr(10))[0][:80]
        print(f'    \033[2m{line}\033[0m')
    if len(prompts) > 3:
        print(f'    \033[2m... +{len(prompts)-3} more\033[0m')
    for sid in resume_ids:
        print(f'    \033[36m↪ claude -r {sid}\033[0m')
    print()
" 2>/dev/null
fi

echo ""
echo -e "${DIM}Tip: claude -r (interactive picker) 또는 claude -r <session-id>${RESET}"
