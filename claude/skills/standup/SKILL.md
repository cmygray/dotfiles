---
name: standup
description: 일일 standup 초안 생성. "standup", "데일리", "오늘 standup", "스탠드업" 등의 요청에 반응. 세션 히스토리·Reminders·GitHub·Slack을 종합해 Won의 형식으로 초안을 만들고, 확인 후 #group-product Daily update 스레드에 전송.
allowed-tools: Bash, Read
---

# standup — Daily standup 초안 생성

매일 평일 아침 `#group-product` Daily update 스레드에 올릴 standup 초안을 생성한다.
세션 히스토리, Reminders, GitHub 활동, Slack 활동을 종합해서 Won의 형식대로 정리하고, 확인 후 Slack에 전송한다.

---

## ⚠️ STEP 0 (필수): 현재 날짜 확인

**워크플로우 시작 전에 무조건 `date` 실행해서 오늘 날짜·요일을 확정.**
대화 컨텍스트의 날짜 추론에 의존 금지 (세션이 며칠 이어진 경우 stale).

```bash
date '+%Y-%m-%d %A'
# 예: 2026-05-26 Tuesday
```

이 결과를 `TODAY` 변수로 잡고 이후 모든 단계에 사용. 모든 날짜 계산 (어제, 스프린트 D-day, 캘린더 쿼리)의 기준점.

---

## 트리거 조건 (자동 실행 시)

다음 조건 모두 만족할 때만 실행:
1. **평일** (월~금)
2. **한국 공휴일 아님** (아래 하드코딩 목록 참고)
3. **오늘 종일 휴가 이벤트 없음** — `gws calendar`에서 `휴가|연차|PTO|vacation` 키워드 검색
   - **종일 휴가 (4시간 이상)** → 스킵
   - **반차 (3~5h)** → 진행 + `출근 (반차)` 표기, 반차 시간대 명시
   - **반반차 (~2h)** → 진행 + `출근 (반반차)` 표기, 시간대 명시
   - 캘린더 이벤트의 `start.dateTime` ~ `end.dateTime`로 duration 계산
4. **오늘 이미 standup을 올리지 않았음** — Slack에서 `from:<@UNVC0AHQE> in:#group-product after:today` 확인

조건 1, 2, 4 미충족 시 그날은 스킵. 3은 부분 휴가일 때 표기만 변경하고 진행.

---

## "어제" 정의

- **화~금**: 어제 = 어제 (D-1)
- **월요일**: 어제 = 직전 금요일 (D-3)
- **공휴일 다음날**: 어제 = 직전 평일

Python으로 계산 권장.

---

## 데이터 수집 우선순위 (개정)

**작업 식별의 신뢰도 순서:**
1. **현재 스프린트 Won 할당 작업** (Notion) — 가장 정확
2. **어제 데일리 스탠덥 미팅노트의 Action Items** — Won 본인 항목 직접 추출
3. **어제 머지·OPEN PR (Won 작성)** — 코드로 증명된 작업
4. **오늘 캘린더 미팅** — prep 작업 단서 (예: PRD 리뷰 미팅 → "PRD 리뷰 및 설계 검토" 추가)
5. **Reminders Today-Work 미완료** — 부수 누적 풀
6. **에이전트 이름 / 세션 활동** — **검증용 보조** (단독 신뢰 X, 위 소스와 교차 확인용)

⚠️ **금지:** 에이전트 이름을 곧바로 standup 항목으로 변환하지 말 것. 탐색·실험 세션이 많아 1:1 매핑이 안 됨.

---

## 데이터 수집 (병렬)

### 1. 어제 데일리 스탠덥 미팅노트 (최우선)

매일 10시 데일리 스탠덥 후 Notion에 미팅노트가 생성됨. **Action Items 섹션**에 `**원님:**` 또는 `**원님, 다른분:**` prefix가 붙은 항목이 본인 작업.

```
notion-search:
  query: "YYYY-MM-DD AI Writing Daily"
  filter: created_date_range = 어제
→ 페이지 fetch
→ "### Action Items" 섹션 파싱
→ "원님:" prefix 항목 추출, 체크박스 상태 ([x] 완료 / [ ] 미완료) 확인
```

체크박스 상태가 그날 마무리된 항목과 미완료 항목을 구분해줌.

### 2. 어제 백그라운드 에이전트 이름 (보조, 검증용)

`~/.claude/projects/**/*.jsonl`에서 `type: agent-name` entry로 에이전트 이름 추출.
**에이전트 이름은 단서일 뿐, 그 자체로 standup 항목이 되지 않음**. 위 1번 + Sprint task + PR과 교차 검증 후 사용.

```python
import json, glob, os
projects_dir = os.path.expanduser("~/.claude/projects")
agents_on_target = []
for jsonl in glob.glob(f"{projects_dir}/**/*.jsonl", recursive=True):
    if 'subagents' in jsonl:
        continue
    has_target_activity = False
    agent_name = None
    with open(jsonl) as f:
        for line in f:
            try:
                d = json.loads(line)
                if d.get('type') == 'agent-name':
                    agent_name = d.get('agentName')
                if d.get('timestamp', '').startswith(YESTERDAY):
                    has_target_activity = True
            except: pass
    if has_target_activity and agent_name:
        cwd_encoded = jsonl.replace(projects_dir + '/', '').split('/')[0]
        agents_on_target.append((agent_name, cwd_encoded))
```

cwd_encoded → 실제 repo 파악 (예: `-Users-classting-won-Workspace-generative-ai-service` → `generative-ai-service`)

### 2. 어제 세션 첫 user 메시지 (보조)

`agent-name`이 없는 세션(인터랙티브 세션 등)은 첫 user msg로 보강.

```bash
find ~/.claude/projects/ -name "*.jsonl" | xargs ls -lt 2>/dev/null | grep "$(date -j -v-1d +'%b %d')" | grep -v subagent
```

**주의:** `jq`로 전체 JSON 파싱 시 control character 에러 가능. 단일 jq pipe 사용.

### 3. GitHub 활동 (상태 마커 핵심 소스)
```bash
# 머지된 PR → (완료) 마커 후보
gh search prs --author=@me --merged-at="${YESTERDAY}..*" --json title,repository,number,mergedAt --limit 20

# 닫힌 이슈 → (완료) 마커 후보
gh search issues --author=@me --state=closed --closed=$YESTERDAY..* --json title,repository --limit 10

# 어제 업데이트된 OPEN PR → (진행중) 마커 후보
gh search prs --author=@me --updated="${YESTERDAY}..*" --state=open --json title,repository,number --limit 20
```

### 4. Today-Work Reminders
```bash
# 미완료 항목 → 오늘 계획
remindctl list "Today-Work" --json | jq -r '.[] | select(.isCompleted == false) | .title'

# 오늘 완료한 항목 (있으면 어제 한 일에 추가 고려)
TODAY=$(date +%Y-%m-%d)
remindctl list "Today-Work" --json | jq -r --arg t "$TODAY" '.[] | select(.isCompleted == true and (.completionDate // "" | startswith($t))) | .title'
```

### 5. 어제 Slack 활동 (옵션, 컨텍스트 강화)
```
slack_search_public: from:<@UNVC0AHQE> in:#group-product after:어제 before:오늘
```
회의록·인시던트 노트 등 어제 올린 글에서 작업 단서 추출.

### 6. 현재 스프린트 (Sprint progress)

**전체 태스크를 일일이 fetch하지 말 것** (34개를 fetch하는 건 비효율 + 컨텍스트 낭비). 다음 우선순위로 시도:

#### 6a. `Notion:database-query` 스킬 (권장)

Tasks 데이터소스를 작업자/스프린트 조건으로 직접 쿼리.

```
Notion:database-query
  database: "작업" (또는 collection://30eab0ab-d3a5-4ea0-9e88-eafd40b5391d)
  filter:
    - 작업자 contains <Won user_id: 1cdd0b71-d855-4a96-8b8f-61e1d7c15f4d>
    - 스프린트 contains <현재 스프린트 page URL>
```

결과로 Won 할당 task 목록(제목/상태/ID)만 반환.

#### 6b. 현재 스프린트 페이지 식별

먼저 `notion-search`로 `"스프린트 상태: 현재"` 페이지 찾기:
```
notion-search: "스프린트" filter created_date_range >= 최근 4주
→ 페이지 properties의 "스프린트 상태": "현재" 확인
→ "날짜:start" ~ "날짜:end" 기간으로 D-day 계산
```

#### 6c. (Fallback) 페이지 fetch 후 작업 URL 일괄 처리

`database-query` 미가용 시에만:
- 스프린트 페이지 fetch → properties의 작업 URL 목록 추출
- Agent에 위임해서 병렬 fetch + 작업자 필터 (Won user_id matching)

#### Won의 스프린트 작업 분류

- **진행 중** → 어제·오늘 양쪽에 자동 등장 (선택 대상 X)
- **할 일** → 후보 풀에 포함
- **완료** → 어제 섹션에 `(완료)` 마커로 추가 (어제 완료된 경우)
- **리뷰 중** → 진행중 취급

헤더: `*스프린트 N D-X*` 표기 (스프린트 마감일까지 평일 기준).

---

## 항목 표현 규칙 (Won 실제 스타일)

### 제목 형식

1. **Notion 태스크 풀 제목** 그대로 사용. 줄이지 말 것.
   - 예: `(서논술형) 이전 평가 불러오기 시 성취기준 메타데이터 로드`
2. **서비스/도메인 prefix in parens**:
   - `(서논술형)`, `(계정서비스)`, `(라이팅)` 등
3. **사용자 의도 그대로**:
   - `serverless -> aws cdk 전환 후 발생한 환경변수 갱신 문제 조사`
   - `sentry 노이즈 방지를 위한 조치`
4. **테마 임의 합성 금지**:
   - ❌ `성취기준 관리 / 채점 고도화` (두 테마 임의 묶기)
   - ✅ 각각 별도 bullet

### Sub-bullet 사용 기준

Sub-bullet은 **테마 아래의 구체적 변경/하위 작업**일 때만:
```
• sentry 노이즈 방지를 위한 조치
    ◦ (계정서비스) 웨일스페이스-네이버웍스 전환 후 남아있던 sqs 연동 제거
```

별개 Notion 태스크끼리는 **각각 top-level bullet**으로 (위아래로 nest 금지).

### 상태 마커 (Won 실제 어휘)

- `(완료)` — 머지/배포 끝
- `(진행중)` — 코드 작성 중
- `(리뷰중)` — PR 리뷰 받는 중
- `(리뷰 대응)` — 받은 리뷰 피드백 처리 중
- `(조사)` / `(수정)` 등 — 작업 단계 표현
- **마커 없음** — 단순 활동 (예: PRD 리뷰)

상태는 Notion 태스크의 `진행 상태` 필드값을 그대로 매핑하거나, PR review state 기반 추론.

---

## Won의 standup 형식

```
출근
어제
• (서논술형) 이전 평가 불러오기 시 성취기준 메타데이터 로드 (리뷰중)
• serverless -> aws cdk 전환 후 발생한 환경변수 갱신 문제 조사
• sentry 노이즈 방지를 위한 조치
    ◦ (계정서비스) 웨일스페이스-네이버웍스 전환 후 남아있던 sqs 연동 제거
오늘
• (서논술형) 이전 평가 불러오기 시 성취기준 메타데이터 로드 (리뷰 대응)
• serverless -> aws cdk 전환 후 발생한 환경변수 갱신 문제 수정
• sentry 노이즈 방지를 위한 조치
• 글쓰기 발표모드 PRD 리뷰 및 설계 검토
• 프롬프트 eval 리포트 포맷 개선
```

**불릿 스타일:** 유니코드 문자 사용 (슬랙은 `-` 마크다운을 자동 렌더링하지 않음)
- 1단계: `•` (U+2022 bullet)
- 2단계: `    ◦` (4-space + U+25E6 white bullet)

**규칙:**
- 한글 소문자, 명사형 (서술형 X)
- PR 번호 / URL / 시각 / 라벨 생략
- 2-5개 bullet (많으면 테마로 묶기)
- **각 sub-bullet 끝에 상태 마커** — `(완료)`, `(진행중)`
- 진행 중 작업은 어제·오늘 양쪽 등장 가능
- 블로커 섹션은 있을 때만 추가 (없으면 생략)
- `출근` 접두어 (Won 스타일), 반차/반반차 시 `출근 (반반차 15:00~17:00)` 등 시간대 명시

### 상태 마커 추론

- `(완료)` 신호:
  - 어제 머지된 PR이 그 테마에 속함 (`gh search prs --merged-at=YESTERDAY`)
  - 어제 닫힌 이슈
  - Reminders Today-Work에서 어제 `isCompleted=true && completionDate startswith YESTERDAY`
  - 에이전트 세션이 어제 마지막 활동 후 dead (조심: 일찍 종료된 것일 수도)
- `(진행중)` 신호:
  - 작업 흔적은 있는데 PR이 아직 open
  - 어제 활동한 에이전트 세션이 alive
  - Reminders 미완료 + 어제 활동
- **마커 없음**: 신호가 불확실하면 마커 생략 (Won 본인이 추가하도록)

---

## "오늘" 섹션 구성 — 휴먼인더루프 (필수)

오늘 할 일은 다음 두 가지로 구성:

### A. 자동 포함 (Won 선택 대상 X)

어제 진행 중이던 작업 = 자연스럽게 오늘 이어짐:
- 어제 활동한 에이전트가 alive
- OPEN PR
- 스프린트 27 진행 중인 Won 할당 작업

→ **standup "오늘" 섹션에 자동 포함**, 사용자 확인 X.

### B. 추가 선택 (휴먼인더루프)

부수 누적 풀 = Won이 추가할지 결정:
- **Reminders Today-Work 미완료** 항목 (`/daily-note`의 누적 작업)
- 스프린트 中 "할 일" 상태 작업
- 어제 자연 연결 (avatar-handler 같은 임시 작업 등 unclassified)

선택 절차:
1. 후보 목록을 카테고리별로 표시:
   ```
   📥 추가 선택 후보 — YYYY-MM-DD
   
   [Reminders 미완료]
   [ ] B1. ⚠️ <high priority 항목>
   [ ] B2. <일반 항목>
   ...
   
   [스프린트 27 할 일]
   [ ] S1. <스프린트 작업>
   ...
   
   [어제 자연 연결]
   [ ] C1. <어제 1회성 작업>
   ```
2. Won이 선택 (예: `B1 C1` 또는 `없음`)
3. 선택된 항목을 "오늘" 섹션에 추가

**중요:**
- 진행중 항목은 이미 자동 포함되므로 후보로 표시 X (UX 마찰).
- 취소된 작업 / `[폐기]` 키워드 작업은 후보에서 제외.
- 헤더에 `*스프린트 N D-X*` 표기 (스프린트 마감일까지 평일 기준).

---

## 확인 워크플로우

선택된 항목으로 초안 구성 후 대화창에 표시:

```
📋 Standup 초안 — YYYY-MM-DD  *스프린트 N D-X*

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
- **취소 작업 처리**: 사용자가 "X 작업 취소" 언급 시 어제·오늘 양쪽에서 제외 + Reminders 항목도 삭제 제안
- **사용자 정정 우선**: 자동 감지된 활동이라도 "X 안 했음" 정정 시 즉시 제외 (자동 신호 > 사용자 발언이 아니라 사용자 발언 > 자동 신호)

## 캐치하기 어려운 항목 (확인 후 추가)

다음은 자동 감지 한계가 있어 사용자에게 확인받거나 휴리스틱 보강 필요:

### 1. Notion 태스크/이슈 없이 진행된 작업
- 슬랙 메시지, 세션 첫 user msg 등을 단서로 사용
- PR이 열렸으면 PR 제목 + 본문에서 단서 추출 (예: `feat: sentry sqs cleanup`)

### 2. 오늘 미팅에서 파생되는 prep 작업
- 캘린더 이벤트 제목에서 추론: `글쓰기 발표모드 PRD 리뷰` → 오늘 항목 `글쓰기 발표모드 PRD 리뷰 및 설계 검토`
- 미팅 타입: `PRD 리뷰`, `회고`, `데일리`, `바이위클리` 등 키워드 매칭
- prep 작업으로 추출할 시간대: 회의 시작 30분 ~ 1시간 전

### 3. 어제 데일리 스탠덥의 Won 발화 내용
- 미팅노트에는 본인 발화 요약도 있음 (Action Items 외에 진행 상황·논의 내용)
- 이걸 어제 작업 식별에 보조 신호로 사용
