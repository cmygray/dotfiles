# Sprint Finalize

스프린트 계획의 산출물을 생성하고 마무리합니다 (Phase 7-8).

## 용도

- `/sprint-plan` 전체 흐름 중 Phase 7-8만 독립 실행
- 작업 분해가 완료된 후 노션 등록 및 마무리

## 전제 조건

상태 파일(`.claude/sprint-plan/current-state.md`)에 다음이 완성되어 있어야 함:
- Tasks 섹션 (작업 분해 결과)
- Use Cases 섹션 (유스케이스 정의)
- Notion References (스프린트, 계획회의 페이지)

## Phase 7: Artifacts Generation

### 7.1 계획회의 문서 작성

노션 계획회의 페이지에 다음 내용 작성:

```markdown
# 스프린트 플래닝

## 스프린트 목표
- {상태 파일의 Requirements Summary 기반}

### {에픽명} ({총pt})
- User Story X-1 ({pt}pt) F:{f}, B:{b}
  - {mutation/기능 설명}
- User Story X-2 ({pt}pt) F:{f}, B:{b}
  - ...

## 총 산정 포인트
- {총합}pt

## plan prompt (토글)
- 대원칙:
  - ...
- 설계 세부사항:
  - ...
```

### 7.2 Tasks DB 등록

상태 파일의 Tasks 섹션을 파싱하여 노션에 등록:

**등록 순서**:
1. 상위 작업 먼저 생성
2. 생성된 상위 작업 ID로 하위 작업 생성

**상위 작업 속성**:
```json
{
  "작업": "User Story X-Y: {제목} ({총pt})",
  "규모": "{총 포인트}",
  "스프린트": ["{스프린트 페이지 ID}"],
  "프로그램": ["{프로그램 ID}"],
  "태그": ["프론트엔드", "백엔드", ...]
}
```

**하위 작업 속성**:
```json
{
  "작업": "{설명} ({pt}pt) F:{f}, B:{b}",
  "규모": "{포인트}",
  "상위 작업": ["{상위 작업 ID}"],
  "스프린트": ["{스프린트 페이지 ID}"],
  "프로그램": ["{프로그램 ID}"]
}
```

### 7.3 Plan Prompt 처리 (useSpeckit=true인 경우)

1. 상태 파일의 Plan Prompt 섹션 확인
2. 사용자에게 확인:
   ```
   Plan Prompt가 준비되었습니다.

   1. /speckit.plan 지금 실행
   2. 프롬프트만 확인 (나중에 수동 실행)
   3. 건너뛰기

   선택:
   ```
3. 선택에 따라 처리

## Phase 8: Finalization

### 8.1 결정사항 기록

계획회의 문서에 "결정사항 및 근거" 섹션 추가:
- 주요 설계 결정
- 스코프 조정 이유
- 제외된 항목 및 사유

### 8.2 요약 출력

```markdown
## 스프린트 {N} 계획 완료

### 요약
- 총 작업 수: {상위 X개, 하위 Y개}
- 총 포인트: {pt}
- 프론트엔드: {f}pt / 백엔드: {b}pt

### 생성된 작업
| 작업 ID | 제목 | 포인트 |
|---------|------|--------|
| TASK-XXX | ... | Xpt |

### 노션 링크
- 스프린트: {URL}
- 계획회의: {URL}
- 작업 목록: {필터된 뷰 URL}

### 다음 단계
- [ ] 작업자 배정
- [ ] 마감일 설정
- [ ] /speckit.plan 실행 (미완료 시)
```

### 8.3 상태 파일 아카이브

```bash
mv .claude/sprint-plan/current-state.md \
   .claude/sprint-plan/sprint-{N}-state.md
```

## 완료 조건

- [x] 노션 계획회의 문서 업데이트됨
- [x] 모든 작업이 Tasks DB에 등록됨
- [x] (조건부) Plan Prompt 처리됨
- [x] 상태 파일이 아카이브됨

## 사용 예시

```
/sprint-finalize

상태 파일을 확인합니다...
- Sprint: 17
- Tasks: 4개 상위작업, 12개 하위작업

노션에 작업을 등록합니다...
✓ 상위 작업 4개 생성 완료
✓ 하위 작업 12개 생성 완료

계획회의 문서를 업데이트합니다...
✓ 스프린트 목표 작성
✓ 작업 분해 내용 작성
✓ 총 산정 포인트: 56pt

Plan Prompt가 준비되었습니다.
> 1. /speckit.plan 지금 실행
> 2. 프롬프트만 확인
> 3. 건너뛰기
선택: 2

---
Plan Prompt:
- 대원칙:
  - 사전에 구현 상태를 먼저 파악하고 플랜을 도출한다
  ...
---

상태 파일을 아카이브합니다...
✓ sprint-17-state.md로 저장됨

## 스프린트 17 계획 완료!

노션 링크:
- 계획회의: https://notion.so/...
- 작업 목록: https://notion.so/...
```

## 에러 처리

### Tasks 섹션이 비어있을 때
```
오류: Tasks 섹션이 비어있습니다.
/sprint-plan 또는 /sprint-decompose를 먼저 실행하세요.
```

### 노션 연결 실패
```
오류: 노션 API 연결 실패
- Sprint Page ID: {id}
- 상태: 접근 불가

노션 페이지 권한을 확인하거나 다시 시도하세요.
```
