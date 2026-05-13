---
name: daily-note
description: 오늘의 할 일 관리. "오늘의 할 일", "일감", "오늘 일감", "하루 시작", "오늘 계획", "할 일 목록", "할 일 시작", "할 일 추가" 등의 요청에 반응. Reminders Today 리스트를 단일 소스로 사용.
allowed-tools: Bash(remindctl *), Bash(gws *), Bash(date *), Bash(echo *), Bash(pbcopy)
---

# daily-note — 오늘의 할 일

## 데이터 소스

- 업무: Reminders `Today-Work` 리스트
- 개인: Reminders `Today-Personal` 리스트

```bash
remindctl list "Today-Work" --json
remindctl list "Today-Personal" --json
```

---

## 모드 판단

| 조건 | 모드 |
|------|------|
| Today 리스트가 비어 있고 플래닝 의도 | **Mode 1: 플래닝** |
| 태스크 추가 의도 ("할 일: ...", URL 포함 등) | **Mode 2: 태스크 추가** |
| "할 일 목록", "할 일 현황" 등 조회 의도 | **Mode 3: 진행 보고** |
| "할 일 시작 N" 또는 "할 일 시작 {이름}" | **Mode 4: 할 일 시작** |

---

## Mode 1: 플래닝

### 1. 오늘 일정 수집

```bash
TODAY=$(date +%Y-%m-%d)
gws calendar events list --params "{\"calendarId\":\"primary\",\"timeMin\":\"${TODAY}T00:00:00+09:00\",\"timeMax\":\"${TODAY}T23:59:59+09:00\",\"singleEvents\":true,\"orderBy\":\"startTime\"}"
```

### 2. Reminders 전체 미완료 항목 수집 (Today 제외)

```bash
remindctl show all --json
```

`isCompleted: false` + `listName != "Today"` 필터링. 정렬:
1. due=오늘 또는 overdue 먼저
2. priority 높은 순

### 3. 후보 목록 출력 후 선택 대기

```
📅 오늘 일정:
- 10:00-10:30 AI Writing Daily Scrum | 9A회의실

📋 오늘 할 일 후보:
 1. 세탁조 청소해라 (due: Apr 27) | Next Actions
 2. ...

번호를 입력하세요 (예: 1 3)
```

### 4. 선택 항목 → Today 리스트에 추가

```bash
remindctl delete <id> --force
remindctl add "제목" --list "Today" --due today --notes "URL"
```

---

## Mode 2: 태스크 추가

업무/개인 구분:
- 업무 관련 → `Today-Work`
- 개인 관련 → `Today-Personal`
- 불분명 시 사용자에게 확인

```bash
remindctl add "제목" --list "Today-Work" --due today --notes "관련 URL (있는 경우)"
remindctl add "제목" --list "Today-Personal" --due today --notes "메모 (있는 경우)"
```

확인 출력: `"[제목]" Today-Work/Personal에 추가했습니다.`

---

## Mode 3: 진행 보고

### 1. 데이터 수집 (jq로 완전 필터링, head 사용 금지)

```bash
TODAY=$(date +%Y-%m-%d)

# 캘린더 일정
gws calendar events list --params "{\"calendarId\":\"primary\",\"timeMin\":\"${TODAY}T00:00:00+09:00\",\"timeMax\":\"${TODAY}T23:59:59+09:00\",\"singleEvents\":true,\"orderBy\":\"startTime\"}"

# Reminders: 배열로 수집 (모든 데이터 유지)
WORK_INCOMPLETE=$(remindctl list "Today-Work" --json | jq '[.[] | select(.isCompleted == false)]')
PERSONAL_INCOMPLETE=$(remindctl list "Today-Personal" --json | jq '[.[] | select(.isCompleted == false)]')

WORK_COMPLETED=$(remindctl list "Today-Work" --json | jq --arg today "$TODAY" '[.[] | select(.isCompleted == true and (.completionDate | startswith($today)))]')
PERSONAL_COMPLETED=$(remindctl list "Today-Personal" --json | jq --arg today "$TODAY" '[.[] | select(.isCompleted == true and (.completionDate | startswith($today)))]')
```

### 2. 번호 부여 로직 (프로세스 치환 사용)

**규칙:**
- 미완료 항목에만 순번 부여 (업무 → 개인 순, 전체 통합)
- HIGH 우선순위 항목을 먼저 표시 (⚠️ 마크)
- 완료 항목은 번호 없음 (✓ 마크로만 표시)

**구현:**
- while 루프에서 프로세스 치환 `< <(...)` 사용
- 서브쉘이 아닌 메인 쉘에서 변수 유지
- 공백 라인 스킵: `[ -z "$title" ] && continue`

```bash
ITEM_NUM=1

# 업무 - HIGH 우선순위
while IFS= read -r title; do
  [ -z "$title" ] && continue
  echo "$ITEM_NUM. ⚠️  $title"
  ITEM_NUM=$((ITEM_NUM + 1))
done < <(echo "$WORK_INCOMPLETE" | jq -r '.[] | select(.priority == "high") | .title')

# 업무 - 기타
while IFS= read -r title; do
  [ -z "$title" ] && continue
  echo "$ITEM_NUM. $title"
  ITEM_NUM=$((ITEM_NUM + 1))
done < <(echo "$WORK_INCOMPLETE" | jq -r '.[] | select(.priority != "high") | .title')

# 개인 - HIGH → 기타 동일 로직
# 모든 항목 출력 후 ITEM_NUM은 마지막 번호 유지
```

### 3. 출력 형식

```
오늘의 할 일 (완료 N / 전체 M)

💼 업무 (완료 n/m)
1. ⚠️  우선 태스크 1
2. ⚠️  우선 태스크 2
3. 일반 태스크 1
4. 일반 태스크 2
── 완료 ──
✓ 완료된 태스크 1

🏠 개인 (완료 n/m)
5. 개인 미완료 태스크 1
── 완료 ──
✓ 완료된 개인 태스크 1
```

### 4. 주의사항

- 캘린더 일정이 없으면 일정 섹션은 생략
- 미완료 항목이 없으면 섹션 표시 생략 (하지만 카운트는 0/0 표시)
- 완료 항목이 없으면 "── 완료 ──" 구분선과 완료 항목 표시 생략
- jq 필터링에서 head 절대 사용 금지 (배열 전체 유지 필수)
- completionDate는 ISO 8601 형식이므로 날짜 비교는 `startswith()` 활용

---

## Mode 4: 할 일 시작

### 1. 태스크 파악

```bash
remindctl list "Today-Work" --json
remindctl list "Today-Personal" --json
```

두 리스트를 합쳐 💼 업무 → 🏠 개인 순으로 번호 부여.
번호 지정 → 해당 번호 항목
이름 지정 → title 유사 항목

### 2. 레포 경로 추론

다음 순서로 추론:
1. **notes의 GitHub URL** — `classtinginc/{repo}` 패턴
2. **태스크 제목/키워드**
3. **Today 리스트 전체 컨텍스트 + 캘린더 맥락**
4. **추론 불가** — `cd` 없이 `cc`만 사용

레포 매핑:
- `ai-web`, `writing`, `서논술형`, `고쳐쓰기`, `e2e` → `~/Workspace/ai-web`
- `ai-writing` → `~/Workspace/ai-writing`
- `account-service`, `계정`, `인증` → `~/Workspace/account-service`
- `organization`, `기관`, `라이센스` → `~/Workspace/organization`
- `enterprise` → `~/Workspace/enterprise`
- `generative-ai-service` → `~/Workspace/generative-ai-service`
- `minerva-api` → `~/Workspace/minerva-api`
- `classroom-service`, `클래스` → `~/Workspace/classroom-service`

### 3. 워크트리 이름 생성

태스크 내용 기반 kebab-case (2~4 단어):
- `회고 준비` → `retro-prep`
- `Slack 메시지 응답` → `slack-reply`
- `e2e 테스트 스크립트 작성` → `e2e-script`
- `스프린트 대비 리서치` → `sprint-research`

### 4. 이슈 URL 추출 (필수)

notes에서 GitHub 이슈 URL 확인:
- URL 있음: `https://github.com/classtinginc/{repo}/issues/{id}` 형식 추출 → `{issue-url}` 사용
- URL 없음: 없음 처리 (다음 단계에서 제외)

### 5. 에이전트 뷰 프롬프트 생성 후 클립보드 복사

에이전트 뷰 입력창에 붙여넣는 용도. `@{repo}` 노테이션으로 레포 타겟팅.

**이슈 URL 있는 경우 (권장):**
```bash
echo -n '@{repo} {task-content} {issue-url}' | pbcopy
```

**이슈 URL 없는 경우 (레포 있음):**
```bash
echo -n '@{repo} {task-content}' | pbcopy
```

**레포 없는 경우:**
```bash
echo -n '{task-content}' | pbcopy
```

레포 이름 규칙 (`~/Workspace/{repo}` → `@{repo-basename}`):
- `~/Workspace/ai-web` → `@ai-web`
- `~/Workspace/account-service` → `@account-service`
- `~/Workspace/organization` → `@organization`
- `~/Workspace/enterprise` → `@enterprise`

프롬프트를 출력하고 "에이전트 뷰 입력창에 붙여넣으세요 (클립보드에 복사됨)" 확인.
