---
name: todo
description: 할 일 즉석 캡처. "/todo", "투두", "나중에", "기억해" 등의 요청에 반응.
allowed-tools: Bash(gh issue view *), Bash(gh pr view *), Bash(date *), Read, Edit
---

# todo — 유연한 할 일 캡처

사용자 인풋을 파싱하여 `~/.local/share/ct/todos.md`의 `## Manual` 섹션에 추가한다.

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

### 단순 텍스트
```
/todo 마일스톤 설정
```
→ `- [ ] 마일스톤 설정 | added:2026-04-03`

## 저장 형식

```
- [ ] 설명 | due:YYYY-MM-DD | p:high|medium|low | url | added:YYYY-MM-DD
```

모든 필드는 선택적이며, `설명`과 `added`만 필수.

## 동작

1. `~/.local/share/ct/todos.md` 읽기
2. `## Manual` 섹션 끝에 새 항목 추가 (Edit 도구 사용)
3. 추가된 항목을 사용자에게 간결하게 확인

## 완료 처리

```
/todo done tracking plan
```
→ Manual 섹션에서 매칭되는 항목을 `- [x]`로 변경하고 `done:YYYY-MM-DD` 추가
