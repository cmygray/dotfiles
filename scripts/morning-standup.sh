#!/usr/bin/env bash
# morning-standup: 오전 출근 시 실행 — 직전 워킹데이의 미완료 작업 + 액션아이템
# Usage: morning-standup

set -euo pipefail

TODAY="$(date +%Y-%m-%d)"
GH_USER="$(gh api user --jq '.login' 2>/dev/null || echo '')"

# Colors
BOLD='\033[1m'
DIM='\033[2m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
MAGENTA='\033[35m'
RESET='\033[0m'

# ── Find last working day from history.jsonl ────────────
LAST_WORKDAY=$(python3 - "$TODAY" <<'PYEOF'
import json, sys
from datetime import datetime, timezone, timedelta
from pathlib import Path

kst = timezone(timedelta(hours=9))
today = datetime.strptime(sys.argv[1], '%Y-%m-%d').replace(tzinfo=kst).date()

history = Path.home() / '.claude' / 'history.jsonl'
if not history.exists():
    sys.exit(1)

days = set()
with open(history) as f:
    for line in f:
        try:
            e = json.loads(line)
        except json.JSONDecodeError:
            continue
        ts = e.get('timestamp', 0)
        dt = datetime.fromtimestamp(ts / 1000, tz=kst).date()
        if dt < today:
            days.add(dt)

if days:
    print(max(days).isoformat())
PYEOF
)

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

SESSION_RAW=$(python3 - "$LAST_WORKDAY" <<'PYEOF'
import json, sys
from datetime import datetime, timezone, timedelta
from pathlib import Path
from collections import OrderedDict

kst = timezone(timedelta(hours=9))
target = datetime.strptime(sys.argv[1], '%Y-%m-%d').replace(tzinfo=kst)
day_start_ms = int(target.timestamp() * 1000)
day_end_ms = day_start_ms + 86400000

history = Path.home() / '.claude' / 'history.jsonl'
projects = OrderedDict()
with open(history) as f:
    for line in f:
        try:
            e = json.loads(line)
        except json.JSONDecodeError:
            continue
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
        if not idx_file.resolve().is_relative_to(claude_dir.resolve()):
            continue
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

import re
done_pattern = re.compile(
    r'^(ok|done|lgtm|ship it|완료|ㅇㅇ|yes|y|네|commit|push|merge)$'
    r'|commit.*(push|merge)|push.*remote|git push|pr create|gh pr'
    r'|이슈.*(생성|등록|작성)|문서.*(작성|완료)',
    re.IGNORECASE
)

result = []
for proj, prompts in projects.items():
    short = proj.replace(str(Path.home()), '~')
    sessions = session_map.get(proj, [])
    resume_ids = [s['sessionId'] for s in sessions if 'sessionId' in s]
    # Pre-filter: if last prompt matches done pattern, skip
    last = prompts[-1].split('\n')[0].strip() if prompts else ''
    if done_pattern.search(last):
        continue
    result.append({
        'project': short,
        'prompt_count': len(prompts),
        'first_prompts': prompts[:5],
        'last_prompts': prompts[-5:],
        'resume_ids': resume_ids,
    })

json.dump(result, sys.stdout, ensure_ascii=False)
PYEOF
)

if [[ -z "$SESSION_RAW" || "$SESSION_RAW" == "[]" ]]; then
  echo -e "  ${DIM}(직전 워킹데이 Claude 세션 없음)${RESET}"
else
  echo "$SESSION_RAW" | claude -p --model sonnet \
    "TASK: 직전 워킹데이(${LAST_WORKDAY}) Claude 세션에서 미완료 작업만 추출.

INPUT: JSON 배열. 각 항목에 project, first_prompts(세션 초반), last_prompts(세션 말미).

DONE 판단 기준 (하나라도 해당하면 done으로 분류. 관대하게 판단):
- last_prompts에 commit, push, merge, done, ok, 완료, 확인 등 마무리성 단어 포함
- PR 생성, 푸시, 이슈 생성, 문서 작성으로 끝남
- 세션이 자연스럽게 종료된 느낌
- 애매하면 done으로 처리 (false positive보다 false negative가 나음)

IN-PROGRESS 판단 기준 (명확한 경우만):
- last_prompts에 명시적으로 "다음에", "내일", "TODO", "아직" 등 미완료 언급
- 에러/버그 디버깅이 해결 안 된 채 끝남
- 설계/플래닝 논의가 결론 없이 중단됨

OUTPUT RULES:
- done은 절대 출력하지 않는다
- in-progress만 아래 포맷으로 출력
- 머리말, 설명, 마크다운, 코드블록 절대 금지
- 첫 줄부터 바로 결과만

FORMAT (plain text only):
~/project/path — 한줄 요약
    action: 구체적 다음 액션
    resume: claude -r <session-id>

- resume_ids가 비어있으면 resume 줄 생략
- 모든 프로젝트가 done이면 '모든 작업 완료!' 한 줄만 출력" 2>/dev/null | \
  sed -E \
    -e 's|^(~/[^ ]+)|\\033[1m\1\\033[0m|' \
    -e 's/^    action: (.+)/    \\033[33m→ \1\\033[0m/' \
    -e 's/^    resume: (.+)/    \\033[36m↪ \1\\033[0m/' | \
  while IFS= read -r line; do echo -e "$line"; done || \
  # Fallback: claude -p 실패 시 raw 출력
  echo "$SESSION_RAW" | python3 -c "
import json, sys
data = json.load(sys.stdin)
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
