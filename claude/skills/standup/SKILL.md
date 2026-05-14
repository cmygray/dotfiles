---
name: standup
description: 일일 standup 초안 생성. "standup", "데일리", "오늘 standup", "스탠드업" 등의 요청에 반응. 세션 히스토리·Reminders·GitHub·Slack을 종합해 Won의 형식으로 초안을 만들고, 확인 후 #group-product Daily update 스레드에 전송.
allowed-tools: Bash, Read
---

# standup — Daily standup 초안 생성

매일 평일 아침 `#group-product` Daily update 스레드에 올릴 standup 초안을 생성한다.
세션 히스토리, Reminders, GitHub 활동, Slack 활동을 종합해서 Won의 형식대로 정리하고, 확인 후 Slack에 전송한다.

---

## 트리거 조건 (자동 실행 시)

다음 조건 모두 만족할 때만 실행:
1. **평일** (월~금)
2. **한국 공휴일 아님** (아래 하드코딩 목록 참고)
3. **오늘 캘린더에 휴가 이벤트 없음** — `gws calendar`에서 `휴가|연차|PTO|vacation` 키워드 검색
4. **오늘 이미 standup을 올리지 않았음** — Slack에서 `from:<@UNVC0AHQE> in:#group-product after:today` 확인

조건 미충족 시 그날은 스킵.

---

## "어제" 정의

- **화~금**: 어제 = 어제 (D-1)
- **월요일**: 어제 = 직전 금요일 (D-3)
- **공휴일 다음날**: 어제 = 직전 평일

Python으로 계산 권장.

---

## 데이터 수집 (병렬)

### 1. 어제 세션 활동
```bash
# YESTERDAY 변수는 위 로직으로 계산
find ~/.claude/projects/ -name "*.jsonl" | xargs ls -lt 2>/dev/null | grep "$(date -j -v-1d +'%b %d')" | grep -v subagent
```

각 세션 파일에서 첫 user 메시지 추출 → 작업 주제 파악.
**주의:** `jq`로 전체 JSON 파싱 시 control character 에러 가능. 단일 jq pipe 사용 (`jq -r '.[]'` 한번에).

### 2. GitHub 활동
```bash
# 머지된 PR
gh search prs --author=@me --merged-at="${YESTERDAY}..*" --json title,repository,number,mergedAt --limit 20

# 작성/업데이트된 이슈
gh search issues --author=@me --updated="${YESTERDAY}..*" --json title,repository --limit 10
```

### 3. Today-Work Reminders
```bash
# 미완료 항목 → 오늘 계획
remindctl list "Today-Work" --json | jq -r '.[] | select(.isCompleted == false) | .title'

# 오늘 완료한 항목 (있으면 어제 한 일에 추가 고려)
TODAY=$(date +%Y-%m-%d)
remindctl list "Today-Work" --json | jq -r --arg t "$TODAY" '.[] | select(.isCompleted == true and (.completionDate // "" | startswith($t))) | .title'
```

### 4. 어제 Slack 활동 (옵션, 컨텍스트 강화)
```
slack_search_public: from:<@UNVC0AHQE> in:#group-product after:어제 before:오늘
```
회의록·인시던트 노트 등 어제 올린 글에서 작업 단서 추출.

---

## 작업 흐름 단위 그룹핑

각 작업을 다음 기준으로 묶기:
1. **동일 PR/이슈 그룹** → 하나의 테마
2. **동일 도메인** (예: scoring-criteria, cdk migration, lambda runtime) → 하나의 테마
3. 도메인이 같으면 한 bullet + sub-bullet으로 디테일 추가

**예시:**
- PR #643 (LLM judge 4축) + PR #644 (CI workflow 통합) → `글쓰기 평가 게이트 개선` + sub: `llm judge 통합`, `ci workflow 통합`
- CDK Phase 1.5 + Phase 2 → `aws cdk 마이그레이션`
- Lambda 22.x 업그레이드 + 모니터링 대시보드 → `람다 런타임 업그레이드`

---

## Won의 standup 형식

```
출근
어제
• 테마 1
    ◦ 세부 1
    ◦ 세부 2
• 테마 2
오늘
• 항목 1
• 항목 2
```

**규칙:**
- 한글 소문자, 명사형 (서술형 X)
- PR 번호 / URL / 시각 / 라벨 생략
- 2-5개 bullet (많으면 테마로 묶기)
- 진행 중 작업은 어제·오늘 양쪽 등장 가능
- 블로커 섹션은 있을 때만 추가 (없으면 생략)
- `출근` 접두어 (Won 스타일)

---

## 확인 워크플로우

초안을 대화창에 표시 후 응답 대기:

```
📋 Standup 초안 — YYYY-MM-DD

[초안 내용]

전송할까요? (예 / 아니오 / 수정 [내용])
```

응답 처리:
- `예` / `전송` / `ㅇ` / `y` → Slack 전송 절차
- `아니오` / `no` / `n` / `스킵` → 중단
- `수정 [피드백]` → 피드백 반영해서 재생성 후 다시 확인

---

## Slack 전송

```
# 1. 오늘 Daily update 봇 메시지 찾기 (07:00 KST 자동 게시)
slack_search_public:
  query: "좋은 아침입니다 체크인하면서" in:#group-product after:오늘날짜
  → message_ts 획득

# 2. 스레드에 답변
slack_send_message:
  channel_id: C015CP2A457
  thread_ts: <획득한 ts>
  text: <초안 내용>
```

전송 후 permalink 표시.

---

## 한국 공휴일 (하드코딩, 2026)

```
2026-01-01  신정
2026-02-16  설날 연휴
2026-02-17  설날
2026-02-18  설날 연휴
2026-03-01  삼일절
2026-03-02  삼일절 대체
2026-05-05  어린이날
2026-05-25  부처님오신날
2026-06-06  현충일
2026-08-15  광복절
2026-08-17  광복절 대체
2026-09-24  추석 연휴
2026-09-25  추석
2026-09-26  추석 연휴
2026-10-03  개천절
2026-10-05  개천절 대체
2026-10-09  한글날
2026-12-25  성탄절
```

매년 업데이트 필요.

---

## 자동 실행 (ScheduleWakeup 루프)

- 트리거: 07:30 KST 평일
- 루프 패턴: 매 시간 wakeup → 현재 시각 체크 → 07:25~07:35 KST면 standup 워크플로우 실행
- ScheduleWakeup 최대 3600초 제약 → 1시간 단위 폴링
- 실행 후 다음 wakeup 스케줄

```python
# 다음 wakeup 계산 (단순화)
now = datetime.now(KST)
target = now.replace(hour=7, minute=30, second=0)
if now >= target:
    target += timedelta(days=1)
delay = (target - now).total_seconds()
delaySeconds = min(3600, delay)
```

## 노트
- 봇 메시지 timestamp 검색은 07:00 KST 이후에만 유효
- 세션 jsonl 파싱 시 control char escape 에러 주의 → single jq pipe 사용
- 이미 게시된 standup 중복 방지를 위해 매 실행 전 확인
