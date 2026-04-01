---
name: retro
description: '스프린트 회고 보고서 자동 생성 (/retro <keyword> [--repos repo1,repo2] [--notion url])'
---

# Sprint Retrospective Report Generator

인자: $ARGUMENTS

## 사용법

```
/retro <검색키워드> [--repos <저장소목록>] [--notion <노션URL>]
```

- `<검색키워드>`: PR/이슈 검색에 사용할 키워드 (예: "교재발간 OR 공통글감")
- `--repos`: 쉼표 구분 저장소 경로 (기본값: ai-writing 워크스페이스의 관련 저장소들)
- `--notion`: 결과를 동기화할 Notion 페이지 URL (선택)

예시:
```
/retro "교재발간 OR 공통글감" --repos generative-ai-service,ai-web --notion https://notion.so/...
```

## 절차

### 1단계: 인자 파싱

$ARGUMENTS에서 다음을 추출:
- `keyword`: 첫 번째 인자 (따옴표 포함 가능)
- `repos`: --repos 값. 없으면 사용자에게 AskUserQuestion으로 확인
- `notion_url`: --notion 값 (선택)

repos는 다음 경로 규칙을 따름:
- 절대경로가 아니면 ~/Workspace/ 하위로 간주
- 각 경로에서 `gh` CLI가 동작하는지 확인

### 2단계: PR/이슈 수집

각 저장소에 대해 **병렬로 Agent를 실행**하여 다음을 수집:

```
gh pr list --state all --search "<keyword>" --limit 30 --json number,title,createdAt,mergedAt,author,state
gh issue list --state all --search "<keyword>" --limit 30 --json number,title,createdAt,closedAt,state
```

수집된 PR/이슈 목록을 사용자에게 보여주고, **측정 대상에 포함할 항목을 확인**받는다.
사용자가 제외할 항목이 있으면 제거한다.

### 3단계: 상세 분석

확정된 PR/이슈에 대해 **병렬로 Agent를 실행**하여 각각 수집:

```
gh pr view <number> --json title,body,createdAt,mergedAt,comments,reviews
gh api repos/{owner}/{repo}/pulls/<number>/comments
```

수집 항목:
- PR 본문의 버그 원인, 수정 내용
- 리뷰어 피드백 (사람 리뷰, 봇 리뷰 구분)
- Revert 여부 및 사유
- 연쇄 수정 관계 (어떤 PR이 어떤 PR을 유발했는지)

### 4단계: 분류

각 PR을 다음 중 하나로 분류:
- **feat**: 새로운 기능
- **fix**: 버그 수정
- **revert**: Revert
- **rework**: Revert 후 재작업
- **chore**: 기타 (시드, 리팩토링 등)

### 5단계: 시행착오 패턴 식별

다음 패턴을 자동 탐지:
1. **연쇄 수정**: 하나의 feat PR 이후 동일 영역의 fix PR이 2건 이상 연속
2. **Revert → 재작업**: Revert PR과 그 후속 재작업 PR 쌍
3. **핫픽스 연발**: 같은 날 동일 저장소에서 fix PR 3건 이상

각 패턴에 대해:
- 근본 원인 분석
- 개선점 제안

### 6단계: 효율 지표 산출

모든 시각은 **KST(UTC+9)**로 표시한다.

#### 6.1 순전진율
```
순전진율 = feat PR 수 / 전체 PR 수 × 100%
```

#### 6.2 이슈 체류 시간
```
체류 시간 = PR mergedAt - Issue createdAt
```
feat/fix별 평균을 산출한다.

#### 6.3 연쇄 수정 비율
```
연쇄 수정 비율 = 메인 feat PR 수 : 후속 수정 PR 수
```

#### 6.4 저장소 간 동기화 리드타임
백엔드 feat PR 머지 시점 → 프론트엔드 feat PR 머지 시점까지의 시간.
(단일 저장소인 경우 생략)

#### 6.5 기준선 요약
위 지표를 테이블로 정리하고, "다음 프로젝트와 비교할 기준선"으로 명시한다.

### 7단계: 보고서 생성

`docs/retro-<YYYY-MM-DD>.md` 파일로 생성한다.

보고서 구조:
```markdown
# <프로젝트명> 회고 보고서

> 기간: <시작일> ~ <종료일>
> 대상 저장소: <저장소 목록>

## 1. 작업 타임라인
## 2. 시행착오 분석
## 3. 리뷰 프로세스 관찰
## 4. 잔여 기술부채
## 5. 회고 논의 포인트
## 6. 에이전틱 엔지니어링 효율 지표
## 7. 정량 요약
```

### 8단계: 사용자 확인

생성된 보고서를 사용자에게 보여주고 수정 사항이 있는지 확인한다.

### 9단계: Notion 동기화 (선택)

`--notion` URL이 제공된 경우:
1. 해당 Notion 페이지를 fetch
2. "회고 보고서" 섹션이 이미 있으면 replace, 없으면 페이지 하단에 append
3. Notion의 enhanced markdown spec에 맞게 테이블을 `<table>` 태그로 변환

## 회고 미팅 메모 추가

사용자가 회고 미팅 전사본을 제공하면:
1. 전사 오류로 보이는 단어를 발췌하여 사용자에게 확인
2. 확인된 수정사항을 반영하여 "회고 미팅 메모" 섹션을 보고서에 추가
3. Notion에도 동기화

## 주의사항

- 모든 시각은 KST로 표시
- 사람 리뷰와 봇 리뷰를 구분하여 리뷰 프로세스 관찰에 반영
- 보고서에 포함할 저장소와 PR은 반드시 사용자 확인을 거친다
- minerva-api 등 범용 인프라 작업은 특정 프로젝트 회고에서 제외할 수 있음 — 사용자에게 확인
