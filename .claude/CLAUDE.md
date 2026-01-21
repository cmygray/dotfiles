# Development Guide

## Communication
- 모호한 요청은 먼저 질문하고 작업할 것 - AskUserQuestion Tool
- 숨은 전제, 트레이드오프, 실패 케이스를 조기에 언급할 것

## Git & GitHub
- GitHub 페이지 조회 대신 gh CLI 사용 (인증 문제)

## User Info

- 이름: 원 (Won)
- 역할: 개발자

## CLI preference

### Shell Environment
- Nushell 문법 사용 (zsh 대신)
- `&&` 연산자 대신 `;` 사용
- 예시: `command1; command2` (not `command1 && command2`)

### Node.js Version Management
- 프로젝트마다 Node.js 버전이 다름
- 작업 전 `mise ls` 또는 `mise current` 로 현재 버전 확인 필요
- 필요시 `mise use node@<version>` 으로 버전 변경

### AWS Credentials
- AWS 작업 시 `aws-vault exec <profile>` 명령어 사용 필수
- 직접 AWS CLI 사용 금지
- 예시: `aws-vault exec my-profile -- aws s3 ls`

