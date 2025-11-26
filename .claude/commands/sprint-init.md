# Sprint Init

스프린트 계획의 컨텍스트를 설정합니다 (Phase 1).

## 용도

- `/sprint-plan` 전체 흐름 중 Phase 1만 독립 실행
- 이미 초기화된 상태에서 재설정이 필요할 때

## 동작

### 1. 기존 상태 확인

`.claude/sprint-plan/current-state.md` 파일 확인:

| 상황 | 동작 |
|------|------|
| 없음 | 새 상태 파일 생성 |
| Phase 1 미완료 | 이어서 진행 |
| Phase 1 완료 | "덮어쓸까요?" 확인 |

### 2. 프로젝트 설정

`~/.claude/config/sprint-plan.json`에서 설정 로드:

```javascript
// 현재 디렉토리로 프로젝트 추론
const cwd = process.cwd();
const project = Object.entries(config.projects)
  .find(([_, p]) => cwd.startsWith(p.codebasePath));

// 추론 실패 시 사용자에게 질문
if (!project) {
  ask("어떤 프로젝트의 스프린트를 계획하시나요?",
      Object.keys(config.projects));
}
```

### 3. 수집할 정보

사용자에게 다음 정보 요청:

1. **스프린트 번호**: 숫자 입력 또는 "다음" (현재 + 1)
2. **요구사항 소스**:
   - PR 링크
   - 노션 문서 링크
   - 직접 입력 (여러 줄)

### 4. 노션 연동

#### 스프린트 페이지 확인/생성
```
노션에서 "스프린트 {N}" 페이지를 검색합니다.
- 있음: 해당 페이지 사용
- 없음: 새 스프린트 페이지 생성
```

#### 계획회의 문서 생성
```
"스프린트 {N} 계획회의" 페이지를 계획회의 DB에 생성합니다.
- 스프린트 관계 연결
- 초기 템플릿 내용 작성
```

### 5. 상태 파일 생성/업데이트

```markdown
# Sprint Planning State

## Meta
- **Created**: {현재 시간}
- **Last Updated**: {현재 시간}
- **Sprint**: {입력받은 번호}
- **Program**: {프로젝트 설정에서}
- **Program ID**: {프로젝트 설정에서}

## Progress
| Phase | Status | Completed At |
|-------|--------|--------------|
| 1. Context Setup | ✅ completed | {현재 시간} |
| 2. Requirements Analysis | ⏳ pending | - |
...

## Context

### Input Sources
- Source Type: {PR/Notion/Direct}
- URL: {링크가 있으면}
- Content:
```
{직접 입력한 경우 내용}
```

## Notion References
- **Sprint Page**: {스프린트 페이지 URL}
- **Planning Meeting Page**: {계획회의 페이지 URL}
```

## 완료 조건

- [x] 상태 파일의 Meta 섹션 완성
- [x] Input Sources 섹션 완성
- [x] Notion References에 페이지 URL 기록
- [x] Progress 테이블에서 Phase 1 = completed

## 사용 예시

```
/sprint-init

> 스프린트 번호를 입력하세요 (현재: 16, 다음: 17): 17
> 요구사항 소스를 선택하세요:
  1. PR 링크
  2. 노션 문서 링크
  3. 직접 입력
> 선택: 2
> 노션 문서 URL: https://www.notion.so/...

스프린트 17 계획을 시작합니다.
- 프로젝트: ItemBank 구축
- 노션 스프린트 페이지: https://...
- 노션 계획회의 페이지: https://...

상태 파일이 생성되었습니다: .claude/sprint-plan/current-state.md
Phase 1 완료. `/sprint-plan`으로 다음 단계를 진행하세요.
```
