# CLAUDE.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

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
- 기본 쉘: zsh

### Node.js Version Management
- 프로젝트마다 Node.js 버전이 다름
- 작업 전 `mise ls` 또는 `mise current` 로 현재 버전 확인 필요
- 필요시 `mise use node@<version>` 으로 버전 변경

### AWS Credentials
- AWS 작업 시 `aws-vault exec <profile>` 명령어 사용 필수
- 직접 AWS CLI 사용 금지
- 예시: `aws-vault exec my-profile -- aws s3 ls`

### DynamoDB 조회
- DynamoDB 데이터 조회가 필요하면 `ddb` 명령어 사용 (읽기 전용, 쓰기 차단)
- 반드시 `ddb context` 를 먼저 실행해 스키마(테이블명·키 패턴·GSI)를 파악한 후 쿼리
- 환경: `dev` 또는 `stag` 지정 필수
- 테이블명 패턴: `{service}-{env}` (예: `classroom-service-dev`)
- 사용 예시:
  ```
  ddb context                                          # 스키마 전체 출력
  ddb context classroom-service                        # 특정 서비스 스키마만 출력
  ddb dev list                                         # 테이블 목록
  ddb dev desc -t classroom-service-dev                # 테이블 스키마
  ddb dev get -t classroom-service-dev "Classroom#<id>" "Post#<id>"
  ddb dev query -t classroom-service-dev -p "Channel#<id>" -i gsi-1
  ddb stag query -t writing-service-stag -p "Topic#<id>" -i GSI2
  ```

