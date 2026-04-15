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

```bash
remindctl list "Today-Work" --json
remindctl list "Today-Personal" --json
```

섹션 구분 후 번호 부여. **번호는 미완료 항목에만** 부여 (업무 → 개인 순, 전체 통합). 완료 항목은 섹션 하단에 구분선 후 나열.

필터링 규칙:
- **미완료** (`isCompleted: false`): 전부 표시
- **완료** (`isCompleted: true`): `completionDate`가 오늘인 것만 표시 (이전 날 완료 항목 제외)

```
오늘의 할 일 (완료 N / 전체 M)

💼 업무 (완료 n/m)
1. 남은 태스크
── 완료 ──
✓ 완료된 태스크

🏠 개인 (완료 n/m)
2. 개인 태스크
```

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

### 4. 커맨드 생성 후 클립보드 복사

레포 있는 경우:
```bash
echo -n 'cd ~/Workspace/{repo} && cc "{task-content}" --model sonnet --worktree "{worktree-name}"' | pbcopy
```

레포 없는 경우:
```bash
echo -n 'cc "{task-content}" --model sonnet --worktree "{worktree-name}"' | pbcopy
```

커맨드를 출력하고 "클립보드에 복사했습니다" 확인.
