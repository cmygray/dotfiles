---
name: today-sync
description: Notion 스프린트 + GitHub + Google Calendar → todos.md 동기화. "동기화", "sync", "today-sync" 등의 요청에 반응.
allowed-tools: Bash(gh *), Bash(gws *), Bash(date *), Read, Write, Edit, mcp__plugin_Notion_notion__notion-fetch, mcp__plugin_Notion_notion__notion-search
---

# today-sync — 오늘의 할 일 소스 동기화

3개 소스에서 데이터를 수집하여 `~/.local/share/ct/todos.md`를 갱신한다.

## 데이터 파일

- 경로: `~/.local/share/ct/todos.md`
- 섹션: `## Calendar`, `## Sprint`, `## GitHub`, `## Manual`
- **Manual 섹션은 절대 삭제하지 않는다** — 사용자가 `/todo`로 직접 추가한 항목

## 동기화 순서

### 1. Google Calendar

```bash
# 오늘 날짜 계산
TODAY=$(date +%Y-%m-%d)
gws calendar events list --params "{\"calendarId\":\"primary\",\"timeMin\":\"${TODAY}T00:00:00+09:00\",\"timeMax\":\"${TODAY}T23:59:59+09:00\",\"singleEvents\":true,\"orderBy\":\"startTime\"}"
```

결과에서 회의 시간과 제목을 추출하여 Calendar 섹션에 기록:
```
## Calendar
- 10:00-10:30 스탠드업
- 14:00-15:00 스프린트 리뷰
- 가용 시간: ~Xh (1h 타임박스 중 회의 제외 계산)
```

### 2. GitHub

```bash
# 리뷰 요청된 PR
gh pr list --search "review-requested:@me" --json title,url,updatedAt,headRepository --limit 20

# 할당된 이슈
gh issue list --assignee @me --state open --json title,url,labels --limit 20
```

결과를 GitHub 섹션에 기록:
```
## GitHub
### PR Reviews
- [ ] PR제목 — repo | url

### Issues
- [ ] 이슈제목 [label] — repo | url
```

### 3. Notion Sprint

현재 스프린트(스프린트 24)에서 Won 할당 미완료 태스크를 조회한다.

1. `notion-search`로 tasks 데이터소스(`collection://30eab0ab-d3a5-4ea0-9e88-eafd40b5391d`)에서 검색
2. 또는 스프린트 페이지(`https://www.notion.so/32fa8f8c6e438007ae25eb0ede3323ef`)의 인라인 DB에서 태스크 URL 목록을 가져와 개별 fetch

필터 조건:
- 작업자: Won / 김원 (`user://1cdd0b71-d855-4a96-8b8f-61e1d7c15f4d`)
- 진행 상태: `완료`, `취소`, `보관`이 **아닌** 것

Sprint 섹션에 기록 (상태는 동기화 시점에 금방 stale해지므로 포함하지 않는다):
```
## Sprint
- [ ] TASK-123: 태스크제목 | p:높음 | due:2026-04-07 | url
- [ ] TASK-456: 태스크제목 | p:중간 | url
```

### 4. todos.md 갱신 규칙

- Calendar, Sprint, GitHub 섹션은 **전체 교체** (최신 상태 반영)
- Manual 섹션은 **보존** (터치하지 않음)
- 이전 sync에서 있었으나 이번에 없는 항목은 자연히 사라짐 (소스에서 완료/삭제됨)
