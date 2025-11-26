# Sprint Plan - 통합 오케스트레이터

스프린트 계획회의를 체크리스트 기반으로 단계별 진행합니다.

## 시작 시 동작

### 1. 상태 파일 확인
프로젝트 루트의 `.claude/sprint-plan/current-state.md` 파일을 확인합니다.

- **파일 없음**: 새 계획 시작 (Phase 1부터)
- **파일 있음**: 진행 상태를 요약하고 이어서 진행할지 확인

### 2. 프로젝트 설정 로드
`~/.claude/config/sprint-plan.json`에서 프로젝트 설정을 로드합니다.

- 현재 작업 디렉토리 기반으로 프로젝트 추론
- 추론 불가 시 사용자에게 질문

### 3. 상태 파일 템플릿
새로 시작할 경우 아래 템플릿으로 상태 파일을 생성합니다:

```markdown
# Sprint Planning State

## Meta
- **Created**: {timestamp}
- **Last Updated**: {timestamp}
- **Sprint**: {number}
- **Program**: {name}
- **Program ID**: {id}

## Progress
| Phase | Status | Completed At |
|-------|--------|--------------|
| 1. Context Setup | ⏳ pending | - |
| 2. Requirements Analysis | ⏳ pending | - |
| 3. Use Case Definition | ⏳ pending | - |
| 4. Impact Analysis | ⏳ pending | - |
| 5. Interface Design | ⏳ pending | - |
| 6. Task Decomposition | ⏳ pending | - |
| 7. Artifacts Generation | ⏳ pending | - |
| 8. Finalization | ⏳ pending | - |

## Context

### Input Sources
<!-- Phase 1에서 입력 -->

### Requirements Summary
<!-- Phase 2 결과 -->

### Use Cases
<!-- Phase 3 결과 - 사용자 확정 후 기록 -->

### Impact Analysis
<!-- Phase 4 결과 -->

### Interface Design
<!-- Phase 5 결과 -->

### Tasks
<!-- Phase 6 결과 -->

### Plan Prompt
<!-- Phase 7용 - /speckit.plan 호출 프롬프트 -->

## Notion References
<!-- 생성된 노션 페이지 ID들 -->
```

---

## Phase별 체크리스트

### Phase 1: Context Setup
**목표**: 계획회의의 기본 컨텍스트를 설정합니다.

체크리스트:
- [ ] 스프린트 번호 확인/입력
- [ ] 요구사항 소스 입력 (PR 링크, 노션 링크, 또는 직접 입력)
- [ ] 노션 스프린트 페이지 확인 또는 생성
- [ ] 노션 계획회의 문서 생성

**완료 조건**: Input Sources 섹션이 채워지고, 노션 페이지 ID가 기록됨

---

### Phase 2: Requirements Analysis
**목표**: 입력된 요구사항을 분석하고 정리합니다.

체크리스트:
- [ ] 요구사항 소스에서 사용자스토리 추출
- [ ] 각 스토리의 핵심 목표 파악
- [ ] 누락된 정보/모호한 부분 식별
- [ ] 사용자에게 확인 질문

**에이전트 활용**: `sprint-analyzer` 에이전트로 요구사항 분석 수행

**완료 조건**: Requirements Summary 섹션이 채워지고 사용자 확인 완료

---

### Phase 3: Use Case Definition ⚠️ 사용자 주도
**목표**: 구현할 유스케이스를 정의합니다.

**중요**: 이 단계는 사용자의 판단이 가장 중요합니다.

체크리스트:
- [ ] **[사용자]** 초기 유스케이스 아이디어 제시 요청
- [ ] **[에이전트]** 사용자 아이디어 기반 분석
  - 빠진 케이스 제안
  - 에지 케이스 제안
  - 기술적 고려사항 제안
- [ ] **[사용자]** 최종 유스케이스 확정

진행 방식:
1. 사용자에게 먼저 유스케이스 아이디어를 요청
2. 사용자 의견을 받은 후 에이전트가 보완 제안
3. 사용자가 최종 확정

**완료 조건**: Use Cases 섹션이 채워지고 사용자 확정 완료

---

### Phase 4: Impact Analysis
**목표**: 유스케이스가 코드베이스에 미치는 영향을 분석합니다.

체크리스트:
- [ ] **[에이전트]** 코드베이스 분석 수행
  - 관련 모듈/파일 식별
  - 기존 구현 패턴 파악
  - 유스케이스 간 의존성 분석
- [ ] **[에이전트]** 숨은 사전작업 도출
- [ ] **[사용자]** 분석 결과 검토 및 조정

**에이전트 활용**: `impact-analyzer` 에이전트로 코드베이스 분석 수행

**완료 조건**: Impact Analysis 섹션이 채워지고 사용자 검토 완료

---

### Phase 5: Interface Design
**목표**: 주요 인터페이스(GraphQL 스키마, 타입 등)를 정의합니다.

체크리스트:
- [ ] **[에이전트]** GraphQL mutation/query 스키마 제안
- [ ] **[에이전트]** 주요 타입/엔티티 제안
- [ ] **[사용자]** 인터페이스 검토 및 확정

**완료 조건**: Interface Design 섹션이 채워지고 사용자 확정 완료

---

### Phase 6: Task Decomposition ⚠️ 사용자 주도
**목표**: 작업을 상위/하위 작업으로 분해하고 포인트를 산정합니다.

**중요**: 포인트/시간 산정은 전적으로 사용자가 결정합니다.

체크리스트:
- [ ] **[에이전트]** 유스케이스별 작업 분해안 제시
  - Phase 4의 복잡도/변경 범위 정보 기반
  - 작업 간 의존성 명시
  - **시간 추정은 절대 하지 않음**
- [ ] **[사용자]** 분해 수준 조정
- [ ] **[사용자]** 포인트 산정 (F:프론트, B:백엔드)
  - 에이전트가 제공한 복잡도 지표 참고
  - 팀의 속도(velocity) 기반 산정
- [ ] 작업 순서 조정 (의존성 기반)
- [ ] **[사용자]** 최종 확정

**완료 조건**: Tasks 섹션이 채워지고 사용자 확정 완료

---

### Phase 7: Artifacts Generation
**목표**: 계획 결과물을 생성합니다.

체크리스트:
- [ ] 계획회의 문서 내용 작성 (노션)
  - 스프린트 목표
  - 에픽/유저스토리별 작업 분해
  - 총 산정 포인트
- [ ] Tasks DB에 작업 일괄 등록 (노션)
  - 상위 작업 먼저 생성
  - 하위 작업 생성 및 상위 작업 연결
  - 스프린트, 프로그램 속성 설정
- [ ] **[조건부: useSpeckit=true]** Plan Prompt 정리
- [ ] **[조건부]** `/speckit.plan` 실행 여부 확인

**완료 조건**: 노션에 작업이 등록되고, 필요시 plan artifact 생성 완료

---

### Phase 8: Finalization
**목표**: 계획회의를 마무리합니다.

체크리스트:
- [ ] 주요 결정사항 및 근거 기록
- [ ] 계획회의 요약 출력
- [ ] 상태 파일을 아카이브 (sprint-{N}-state.md로 이름 변경)

**완료 조건**: 상태 파일 아카이브 완료

---

## 상태 관리 규칙

1. **각 Phase 완료 시**: 상태 파일의 Progress 테이블 업데이트
2. **중간 결과물**: 해당 섹션에 즉시 기록
3. **컨텍스트 손실 시**: 상태 파일 읽어서 복원

## 노션 작업 등록 형식

상위 작업:
```
작업: "User Story X-Y: {제목} ({총pt})"
규모: {총 포인트}
스프린트: {현재 스프린트}
프로그램: {프로젝트의 프로그램}
태그: [관련 태그들]
```

하위 작업:
```
작업: "{설명} ({pt}pt) F:{f}, B:{b}"
규모: {포인트}
상위 작업: {상위 작업 ID}
스프린트: {현재 스프린트}
프로그램: {프로젝트의 프로그램}
```

---

## 사용 예시

```
/sprint-plan
```

이전 진행 상태가 있으면:
```
이전 계획 진행 상태를 발견했습니다.
- Sprint: 17
- 현재 Phase: 4. Impact Analysis (in_progress)
- 마지막 업데이트: 2025-11-26 14:30

이어서 진행할까요? (y/n/새로 시작)
```
