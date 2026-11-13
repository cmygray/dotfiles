---
name: daily-note
description: 오늘의 할 일 관리. "오늘의 할 일", "일감", "오늘 일감", "하루 시작", "오늘 계획", "할 일 목록", "할 일 추가" 등의 요청에 반응. Reminders "오늘"(마감일 오늘·지남) 기준.
allowed-tools: Bash(remindctl *), Bash(jq *), Bash(gws *), Bash(date *), Bash(echo *)
---

# daily-note — 오늘의 할 일

## ⚠️ STEP 0 (필수): 현재 날짜 확인

**모든 모드 진입 전에 무조건 `date` 실행해서 오늘 날짜·요일을 확정.**
대화 컨텍스트의 날짜 추론에 의존 금지 (세션이 며칠 이어진 경우 stale).

```bash
date '+%Y-%m-%d %A'
# 예: 2026-05-26 Tuesday
```

이후 모든 `TODAY=$(date +%Y-%m-%d)` 사용은 이 결과 기준.

---

## 데이터 소스

"오늘의 할 일" = **미리알림 기본 "오늘" 스마트 목록과 같은 기준**: 미완료이면서 마감일이 오늘이거나 지난 항목. 별도 Today 리스트는 쓰지 않는다 (2026-11-13 `Today-Work`/`Today-Personal` 폐기).

```bash
# 오늘 + 지난 항목을 합쳐 id 기준 중복 제거 (today 필터가 overdue를 포함하는지와 무관하게 안전)
TODAY_ITEMS=$(jq -s 'add | unique_by(.id) | [.[] | select(.isCompleted == false)]' \
  <(remindctl show today --json) <(remindctl show overdue --json))
```

미리알림은 **개인 할 일 전용**이다 (2026-11-13 결정). 업무 할 일은 Notion 스프린트·GitHub에서 관리하고 여기 넣지 않는다.

리스트는 두 개다.

| 리스트 | 용도 |
|------|------|
| `Inbox` | 기본 목록. Siri·빠른 캡처가 들어오는 곳. 정리 전 |
| `Next Actions` | 정리된 다음 행동 |

"오늘 하기로 정함" = 마감일을 오늘로 설정하는 것. 리스트를 옮기지 않는다.

---

## 모드 판단

| 조건 | 모드 |
|------|------|
| 오늘 항목이 비어 있고 플래닝 의도 | **Mode 1: 플래닝** |
| 태스크 추가 의도 ("할 일: ...", URL 포함 등) | **Mode 2: 태스크 추가** |
| "할 일 목록", "할 일 현황" 등 조회 의도 | **Mode 3: 진행 보고** |

---

## Mode 1: 플래닝

### 1. 오늘 일정 수집

```bash
TODAY=$(date +%Y-%m-%d)
gws calendar events list --params "{\"calendarId\":\"primary\",\"timeMin\":\"${TODAY}T00:00:00+09:00\",\"timeMax\":\"${TODAY}T23:59:59+09:00\",\"singleEvents\":true,\"orderBy\":\"startTime\"}"
```

### 2. 후보 수집 (오늘 항목 제외)

```bash
remindctl show all --json
```

`isCompleted: false` 이고 `TODAY_ITEMS`에 없는 항목(마감일 없음 또는 미래). 정렬:
1. 마감일 가까운 순
2. priority 높은 순

### 3. 후보 목록 출력 후 선택 대기

```
📅 오늘 일정:
- 10:00-10:30 AI Writing Daily Scrum | 9A회의실

📋 오늘 할 일 후보:
 1. 세탁조 청소 (due: 12/23) | Next Actions
 2. ...

번호를 입력하세요 (예: 1 3)
```

### 4. 선택 항목 → 마감일을 오늘로

삭제 후 재생성하지 않는다 (id·메모·링크 보존).

```bash
remindctl edit <id> --due today
```

---

## Mode 2: 태스크 추가

- 다음 행동이 분명한 항목 → `Next Actions`
- 아직 다듬지 않은 메모·링크 → `Inbox`
- 업무 할 일이면 미리알림에 넣지 말고, Notion/GitHub에서 관리한다고 알려 준다.

오늘 할 일이면 `--due today`, 아니면 마감일 없이 추가한다.

```bash
remindctl add "제목" --list "Next Actions" --due today --notes "메모·URL (있는 경우)"
remindctl add "제목" --list "Inbox"
```

확인 출력: `"[제목]" Next Actions에 추가했습니다 (마감: 오늘).`

---

## Mode 3: 진행 보고

### 1. 데이터 수집 (jq로 완전 필터링, head 사용 금지)

```bash
TODAY=$(date +%Y-%m-%d)

# 캘린더 일정
gws calendar events list --params "{\"calendarId\":\"primary\",\"timeMin\":\"${TODAY}T00:00:00+09:00\",\"timeMax\":\"${TODAY}T23:59:59+09:00\",\"singleEvents\":true,\"orderBy\":\"startTime\"}"

# 미완료: 위 "데이터 소스"의 TODAY_ITEMS

# 오늘 완료: completionDate가 오늘(KST)인 항목
COMPLETED_TODAY=$(remindctl show completed --json | jq --arg today "$TODAY" \
  '[.[] | select(.completionDate != null and ((.completionDate | sub("\\.[0-9]+";"") | fromdateiso8601 + 32400 | strftime("%Y-%m-%d")) == $today))]')
```

> `completionDate`·`dueDate`는 UTC(`...Z`)로 저장된다 (2026-11-13 확인). 날짜만 있는 마감일도 KST 자정이 UTC 전날 15:00으로 보이므로, 직접 비교할 때는 반드시 KST로 변환한다.

### 2. 정렬과 번호

- 미완료 항목에만 순번을 붙인다. priority `high`(⚠️)를 먼저, 그다음 마감일이 이른 순(지난 항목이 앞).
- 완료 항목은 번호 없이 ✓로만 표시한다.
- 리스트 이름(`Inbox`/`Next Actions`)은 항목 뒤에 붙인다. Inbox 항목이 오늘 목록에 있으면 아직 정리 전이라는 뜻이다.

```bash
echo "$TODAY_ITEMS" | jq -r 'sort_by((.priority != "high"), .dueDate) | to_entries[]
  | "\(.key + 1). \(if .value.priority == "high" then "⚠️  " else "" end)\(.value.title) | \(.value.listName)"'
echo "$COMPLETED_TODAY" | jq -r '.[] | "✓ \(.title)"'
```

### 3. 출력 형식

```
📅 오늘 일정:
- 10:00-10:30 ...

오늘의 할 일 (완료 N / 전체 M)
1. ⚠️  우선 태스크 | Next Actions
2. 지난 태스크 (due: 11/12) | Next Actions
3. 일반 태스크 | Inbox
── 완료 ──
✓ 완료된 태스크
```

### 4. 주의사항

- 캘린더 일정이 없으면 일정 섹션은 생략
- 미완료 항목이 없으면 섹션 표시 생략 (하지만 카운트는 0/0 표시)
- 완료 항목이 없으면 "── 완료 ──" 구분선과 완료 항목 표시 생략
- jq 필터링에서 head 절대 사용 금지 (배열 전체 유지 필수)
- completionDate·dueDate는 UTC이므로 KST로 변환해 비교
