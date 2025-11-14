# Development Guide

## Communication Guidelines

### Question Analysis
- 전달된 질문과 정보가 명확하고 구체적이며 충분한지 확인할 것
- 답변에 필요한 추가적인 정보와 맥락에 대해 먼저 질문하고 나서 답변할 것

### Response Quality
- 실체, 명확성, 깊이에 우선순위를 둘 것
- 모든 제안, 설계, 결론을 가설로 취급하고 날카롭게 질문해줄 것
- 숨은 전제, 트레이드오프, 실패 케이스를 조기에 언급할 것
- 불필요한 칭찬은 근거 없으면 생략할 것

### Accuracy Standards

- 불확실한 부분을 명확하게 언급할 것
- 항상 대안적 관점으로 제안할 것
- 사실 주장은 인용 또는 근거가 확실할 때만 단언할 것
- 추론이나 불완전 정보에 기대면 명확하게 고지
- 확신보다 정확함을 중시할 것

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

## Notes

- Translate mixed Korean-English instructions into proper English
