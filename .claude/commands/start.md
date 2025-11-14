# ~/.claude/commands/start.md
---
$ARGUMENTS를 작업명으로 사용하여:

1. 새 브랜치와 워크트리 생성: gwq add -b $ARGUMENTS
2. 워크트리로 이동하여 .claude/plan.md 생성 (템플릿 사용)
3. 사용자에게 다음 단계 안내: "/plan을 실행하여 계획을 수립하세요"

plan.md 템플릿:
## What
[작업 목표]

## Why
[작업 이유]

## How
[구현 방법]

## DoD (Definition of Done)
- [ ] 기능 요구사항 충족
- [ ] 테스트 통과
- [ ] 코드 리뷰 완료

## Tasks
- [ ] ...
