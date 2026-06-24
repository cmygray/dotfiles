# Codex-Specific Instructions

## Instruction Layout
- 이 `AGENTS.md`는 `scripts/sync-agent-instructions.sh`로 생성됩니다.
- 공통 개인 규칙은 `agent-common/global.md`를 수정합니다.
- 항상 적용할 Won 판단 방식은 `agent-common/won-judgment.md`를 수정합니다.
- 전체 Won 보이스와 Slack식 문체는 항상 적용하지 않습니다. 명시적으로 요청받았을 때 `$as-won` skill을 사용합니다.

## Codex Surface Notes
- Codex의 `rules/*.rules`는 행동 지침이 아니라 명령 실행 권한 정책입니다.
- 행동 지침은 `AGENTS.md`에 두고, 반복 가능한 작업 절차는 skill로 둡니다.
