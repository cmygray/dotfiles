---
name: todo
description: 할 일 즉석 캡처 + 컨텍스트 보존. "/todo", "투두", "나중에", "기억해" 등의 요청에 반응. Reminders(Today-Work/Today-Personal)와 markdown 양쪽에 기록.
allowed-tools: Bash(gh issue view *), Bash(gh pr view *), Bash(date *), Bash(gh issue create *), Bash(remindctl *), Read, Edit, AskUserQuestion
---

# todo — 유연한 할 일 캡처 (컨텍스트 보존)

사용자 인풋을 파싱하여 `~/.local/share/ct/todos.md`의 `## Manual` 섹션에 추가한다.
**컨텍스트 + 추적 링크를 반드시 보존**한다.

## 핵심 규칙 (Machine Agnostic)

**모든 할 일 등록 시 필수:**
1. **충분한 컨텍스트** (상황/문제/에러/요청사항)
2. **추적 링크 최소 1개** (GitHub issue 또는 Slack/Notion/기타)

```
✅ 허용
├─ 컨텍스트 + GitHub issue
├─ 컨텍스트 + Slack/Notion 링크
└─ 컨텍스트 + 자동 생성 issue

❌ 불허
└─ 컨텍스트만 (링크 없음)
```

## 인풋 처리 규칙

인풋 형태를 자동 감지하여 적절히 처리:

### GitHub URL
```
/todo https://github.com/org/repo/issues/123
```
→ `gh issue view` 또는 `gh pr view`로 제목, 라벨 가져옴
→ `- [ ] 이슈제목 [label] | url | added:2026-04-03`

### Notion URL
```
/todo https://www.notion.so/classting/Page-Title-abc123
```
→ URL을 그대로 보존
→ `- [ ] Notion 페이지 확인 | url | added:2026-04-03`

### 마감일 포함 자연어
```
/todo tracking plan 확인, 다음주 월요일까지
/todo 스프린트 리뷰 준비 --due 2026-04-10
```
→ 상대 날짜를 절대 날짜로 변환
→ `- [ ] tracking plan 확인 | due:2026-04-07 | added:2026-04-03`

### 우선순위 포함
```
/todo 긴급 배포 이슈 확인 --p high
/todo 긴급한 건 있는데...
```
→ 명시적(`--p`) 또는 문맥에서 판단
→ `- [ ] 긴급 배포 이슈 확인 | p:high | added:2026-04-03`

### 단순 텍스트 (컨텍스트 함께)
```
/todo 마일스톤 설정
```
→ 컨텍스트만으로는 불허 ❌
→ Slack 링크 필요: `--slack {url}` 또는 `--notion {url}`

```
/todo 마일스톤 설정 --slack https://classting.slack.com/archives/...
```
→ `- [ ] 마일스톤 설정 | https://classting.slack.com/archives/... | added:2026-04-03`

### Slack 메시지 컨텍스트 (신규)
```
/todo slack C041CLPCTQQ/p1776678873562359
```
→ Slack 메시지 컨텍스트 자동 수집
→ GitHub issue 없으면 생성 제안
→ `- [ ] [제목] | GitHub issue | Slack 링크 | added:2026-04-03`

## 저장 형식

```
- [ ] 설명 | due:YYYY-MM-DD | p:high|medium|low | 추적링크 | added:YYYY-MM-DD
```

**필수:**
- `설명`: 할 일 제목
- `added`: 등록 날짜
- `추적링크`: GitHub issue URL 또는 Slack/Notion 링크

**선택:**
- `due`: 마감일
- `p`: 우선순위

## 동작

### 1단계: 입력 검증
- 컨텍스트 확인 (GitHub URL / Notion / Slack / 자연어)
- **추적 링크 검증**: GitHub issue 또는 URL 필수
  - 없으면 → "링크 필요" 오류 또는 생성 제안

### 2단계: 데이터 수집
- GitHub issue 있으면 → 제목/라벨 자동 추출
- Slack URL 있으면 → 메시지 컨텍스트 수집
- Notion URL 있으면 → 그대로 보존

### 3단계: 저장 (두 곳 동시)

**(a) Markdown 기록** — `~/.local/share/ct/todos.md`의 `## Manual` 섹션 끝에 추가 (Edit 도구):

```
- [ ] 설명 | 추적링크 | due:날짜 (선택) | p:우선도 (선택) | added:YYYY-MM-DD
```

**(b) Reminders 동시 등록** — `/daily-note`와 단일 소스 일치하도록 `remindctl add` 실행:

- 업무/개인 구분:
  - 업무 관련(GitHub issue, PR, 팀 Slack 등) → `Today-Work`
  - 개인 관련 → `Today-Personal`
  - 불분명 시 AskUserQuestion으로 확인

```bash
remindctl add "${설명}" \
  --list "${리스트}" \
  --notes "${추적링크}${컨텍스트_요약}" \
  [--due "${due}"] \
  [--priority "${우선도}"]
```

- `--priority`: 입력 `p:high` → `high`, `p:medium` → `medium`, `p:low` → `low` (없으면 생략)
- `--due`: 마감일 있을 때만. `YYYY-MM-DD`, `today`, `tomorrow` 등 remindctl 허용 포맷

### 4단계: 확인
- 추가된 항목을 사용자에게 간결하게 확인
- 형식: `✅ [제목] | [링크] | [마감일/우선도] | Reminders: [리스트]`

## 완료 처리

```
/todo done tracking plan
```

**(a) Markdown**: Manual 섹션에서 매칭되는 항목을 `- [x]`로 변경하고 `done:YYYY-MM-DD` 추가

**(b) Reminders**: `remindctl` 매칭 후 완료 처리
```bash
# Today-Work / Today-Personal에서 제목 매칭 후 complete
ID=$(remindctl list "Today-Work" --json | jq -r ".[] | select(.title | contains(\"${키워드}\")) | .id")
[ -n "$ID" ] && remindctl complete "$ID"
```
