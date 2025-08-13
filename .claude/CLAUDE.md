# Development Guide

## Codebase Analysis

### Using Gemini CLI for Large Codebase Analysis

When analyzing large codebases or multiple files that might exceed context limits, use the Gemini CLI with its massive
context window. Use `gemini -p` to leverage Google Gemini's large context capacity.

#### File and Directory Inclusion Syntax

Use the `@` syntax to include files and directories in your Gemini prompts. The paths should be relative to WHERE you run the
gemini command:

##### Examples

**Single file analysis:**
```bash
gemini -p "@src/main.py Explain this file's purpose and structure"
```

**Multiple files:**
```bash
gemini -p "@package.json @src/index.js Analyze the dependencies used in the code"
```

**Entire directory:**
```bash
gemini -p "@src/ Summarize the architecture of this codebase"
```

**Multiple directories:**
```bash
gemini -p "@src/ @tests/ Analyze test coverage for the source code"
```

**Current directory and subdirectories:**
```bash
gemini -p "@./ Give me an overview of this entire project"
# Or use --all_files flag:
gemini --all_files -p "Analyze the project structure and dependencies"
```

#### When to Use Gemini CLI

Use gemini -p when:
- Analyzing entire codebases or large directories
- Comparing multiple large files
- Need to understand project-wide patterns or architecture
- Current context window is insufficient for the task
- Working with files totaling more than 100KB
- Verifying if specific features, patterns, or security measures are implemented
- Checking for the presence of certain coding patterns across the entire codebase

#### Important Notes

- Paths in @ syntax are relative to your current working directory when invoking gemini
- The CLI will include file contents directly in the context
- No need for --yolo flag for read-only analysis
- Gemini's context window can handle entire codebases that would overflow Claude's context
- When checking implementations, be specific about what you're looking for to get accurate results

### Code Analysis Patterns

#### 이벤트 드리븐 시스템 분석:
1. **serverless.yml에서 이벤트 패턴 추출**
2. **핸들러 파일에서 실제 처리 로직 확인**
3. **Command/Query 구조에서 비즈니스 흐름 파악**
4. **Client 클래스에서 외부 통신 방식 확인**

#### 검색 전략:
- `grep`으로 클래스명, 커맨드명 우선 검색
- `read_file`로 핵심 파일 상세 분석
- `find_path`는 파일 구조 파악용으로만 사용

#### "진입점을 찾고싶다" 요청 시:
1. serverless.yml의 functions와 events 섹션 확인
2. 해당 handler 파일의 실제 구현 확인
3. Command/Handler 패턴에서 비즈니스 로직 추출

#### "전체 영향범위를 알고싶다" 요청 시:
1. 각 핸들러별로 처리하는 이벤트 타입 정리
2. 공통 의존성(Repository, Service) 파악
3. 최종 결과물(알림, 피드 등) 분류

## Documentation

### Architecture Diagram Generation Rules

#### 전체 시스템 흐름 분석 시:
1. **진입점 우선 파악**: Lambda 함수, 컨트롤러, 이벤트 핸들러부터 시작
2. **이벤트 소스 추적**: EventBridge, SQS, HTTP 등의 트리거 확인
3. **내부 의존성 체인 분석**: Handler → Service → Repository 순서로 추적
4. **자기참조 패턴 식별**: 재귀적 메시지 발송, pagination 등 특별 처리

#### Mermaid 다이어그램 작성 시:
1. **노드 ID 중복 방지**: 같은 역할이라도 NTCS, NTCS2 등으로 구분
2. **의존성 제거 옵션**: Repository 레이어는 요청 시에만 표시
3. **색상 분류 체계**: 
   - EventBus: #e1f5fe (파란색)
   - Queue: #fff3e0 (주황색)  
   - Lambda: #f3e5f5 (보라색)
   - Handler: #e8f5e8 (초록색)
4. **화살표 구분**: 실선(직접 호출), 점선(간접/조건부), 텍스트 라벨 활용
5. **레이아웃 조정**: 가로/세로 방향 선택, 노드 크기 조절 가능

#### "다이어그램 요청" 시:
1. 모호한 부분 사전 질문 (Repository 포함 여부, 상세 수준 등)
2. Mermaid 신택스 검증 후 제공
3. 수정 요청 시 구체적 변경사항 반영

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

### Commit Guidelines
- 커밋 요청 시 signoff 커밋할 것
- commit 메시지를 한글로 작성

### GitHub CLI Usage
- GitHub 페이지 조회 대신 gh CLI 사용 (인증 문제)

### Pull Request Guidelines
- PR 오픈 시 PULL_REQUEST_TEMPLATE.md 참고
- PR 메시지를 한글로 작성

### Issue Guidelines
- 이슈 오픈 시 .github/ISSUE_TEMPLATE/ 참고
- 이슈 메시지를 한글로 작성

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

