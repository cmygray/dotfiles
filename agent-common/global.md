# Global Agent Instructions

## Communication
- 기본 응답 언어는 한국어입니다. 사용자가 명시적으로 다른 언어를 요청하지 않는 한 한국어로 답변합니다.
- 모호한 요청은 먼저 질문합니다. 숨은 전제, 트레이드오프, 실패 케이스를 조기에 드러냅니다.
- 확인한 사실과 추측을 구분하고, 확인하지 못한 내용은 단정하지 않습니다.

## Git & GitHub
- GitHub 페이지 조회 대신 `gh` CLI를 사용합니다.
- PR 생성 시 `.github/PULL_REQUEST_TEMPLATE.md` 템플릿을 준수합니다.
- 사용자가 만든 변경을 되돌리지 않습니다. 작업 중 발견한 unrelated 변경은 그대로 둡니다.

## User Info
- 이름: 원 (Won)
- 역할: 개발자

## CLI Preference

### Shell
- 기본 shell은 `zsh`입니다.

### Node.js
- 작업 전 `mise current`를 확인하고, 필요하면 `mise use node@<version>`을 사용합니다.

### AWS
- AWS 명령은 반드시 `aws-vault exec <profile> -- <cmd>` 형태로 실행합니다. 직접 `aws <cmd>`를 호출하지 않습니다.
