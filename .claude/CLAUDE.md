# Development Guide

## AI 협업 가이드

### Gemini 협동 작업 가이드

#### 기본 사용법
```bash
# 기본 협업 모드
gemini -p "작업 내용"

# 전체 파일 컨텍스트 포함
gemini -a -p "코드베이스 전체 분석 필요한 작업"

# 안전한 샌드박스 모드
gemini -s -p "실험적이거나 위험할 수 있는 작업"

# 자동 승인 모드 (신중히 사용)
gemini -y -p "반복적인 단순 작업"

# 체크포인트 활성화 (파일 편집 추적)
gemini -c -p "대규모 리팩토링 작업"
```

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

#### 협업 시나리오별 가이드

**1. 코드 리뷰 및 분석**
```bash
# 보안 취약점 분석
gemini -a -p "전체 코드베이스의 보안 취약점을 분석하고 우선순위를 매겨줘"

# 성능 최적화 포인트 찾기
gemini -a -p "성능 병목지점을 찾고 최적화 방안을 제시해줘"

# 코드 품질 개선
gemini -p "이 함수의 가독성과 유지보수성을 개선해줘" < src/service.ts
```

**2. 대규모 리팩토링**
```bash
# 안전한 리팩토링 (체크포인트 + 샌드박스)
gemini -c -s -p "레거시 코드를 현대적 패턴으로 리팩토링"

# 아키텍처 개선
gemini -a -c -p "마이크로서비스 아키텍처로 모듈 분리"
```

**3. 테스트 및 문서화**
```bash
# 테스트 코드 생성
gemini -p "이 모듈에 대한 포괄적인 테스트 스위트 작성"

# API 문서 자동 생성
gemini -a -p "OpenAPI 스펙 기반 문서 생성"
```

**4. 트러블슈팅**
```bash
# 에러 디버깅
gemini -d -a -p "로그를 분석하여 에러 원인을 찾고 수정 방안 제시"

# 성능 문제 해결
gemini -a -p "메모리 누수나 성능 저하 원인 분석"
```

#### 협업 모범 사례

**Claude와 Gemini 역할 분담**
- **Claude**: 기획, 설계, 코드 리뷰, 정밀한 편집
- **Gemini**: 대량 분석, 패턴 탐지, 실험적 구현, 병렬 작업

**안전한 협업 원칙**
1. 중요한 작업은 반드시 `-c` (체크포인트) 활성화
2. 실험적 작업은 `-s` (샌드박스) 모드 사용
3. 전체 컨텍스트 필요시에만 `-a` 플래그 사용
4. `-y` (YOLO) 모드는 단순 반복 작업에만 제한적 사용

**효과적인 프롬프트 작성**
```bash
# 구체적인 요구사항 명시
gemini -p "NestJS에서 DynamoDB 연동 시 connection pool 최적화"

# 제약사항 포함
gemini -p "TypeScript 엄격 모드 준수하며 JWT 인증 미들웨어 개선"

# 출력 형식 지정
gemini -p "코드 변경사항을 diff 형태로 보여주고 변경 이유 설명"
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

#### 모니터링 및 품질 관리

**메모리 사용량 모니터링**
```bash
gemini --show_memory_usage -a -p "대용량 작업"
```

**텔레메트리 설정**
```bash
# 로컬 텔레메트리
gemini --telemetry --telemetry-target local

# 프롬프트 로깅 (민감 정보 주의)
gemini --telemetry-log-prompts false
```

#### Important Notes

- Paths in @ syntax are relative to your current working directory when invoking gemini
- The CLI will include file contents directly in the context
- No need for --yolo flag for read-only analysis
- Gemini's context window can handle entire codebases that would overflow Claude's context
- When checking implementations, be specific about what you're looking for to get accurate results

#### 주의사항
- 민감한 정보 (API 키, 비밀번호) 포함된 파일 작업 시 주의
- `-y` 모드는 충분한 검토 후 사용
- 대규모 변경 전 반드시 Git 백업 확인
- 샌드박스 모드도 완전히 안전하지 않으므로 중요 작업 전 백업 필수

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

- github 페이지 조회 대신 gh cli를 사용해. 인증때문에 그래.
- 커밋을 요청할 경우 signoff 커밋할것
- commit 메시지를 한글로 작성

### GitHub CLI Usage
- GitHub 페이지 조회 대신 gh CLI 사용 (인증 문제)

### Pull Request Guidelines
- PR 오픈 작업 시 PULL_REQUEST_TEMPLATE.md 을 참고할 것
- PR 메시지를 한글로 작성

### Issue Guidelines
- 이슈 오픈 작업 시 .github/ISSUE_TEMPLATE/ 을 참고할 것
- 이슈 메시지를 한글로 작성

## Notion 작업 관리 가이드

### 사용자 정보
- 이름: 원 (Won)
- 역할: 개발자
- Notion 계정: classting-won@classting.com
- 작업 할당시 나를 멘션하거나 할당자로 설정할 때 이 정보를 활용

### 스프린트 관리 룰
- 스프린트 관련 대화 시 항상 현재 진행중인 스프린트("현재" 상태)를 먼저 식별하여 컨텍스트 제공
- 스프린트 데이터베이스에서 "스프린트 상태"가 "현재"인 항목을 찾아 활성 스프린트 확인
- 티켓 작업 시 해당 스프린트와의 연관성을 항상 고려
- 새 작업 생성 시 현재 스프린트에 자동 연결 고려

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

## HTTP File Testing with Kulala

### .http File Guide

Kulala 플러그인을 사용하여 HTTP 요청을 테스트하기 위한 .http 파일 작성 가이드

#### 기본 요청 구조

```http
# 기본 GET 요청
GET https://api.example.com/users

# POST 요청 with JSON body
POST https://api.example.com/users
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com"
}

# 요청 구분자 (### 또는 빈 줄로 구분)
###

# PUT 요청
PUT https://api.example.com/users/1
Content-Type: application/json

{
  "name": "Updated Name"
}
```

#### 변수 사용

```http
# 변수 정의
@baseUrl = https://api.example.com
@apiKey = your-api-key-here
@userId = 123

# 변수 사용 예시
GET {{baseUrl}}/users/{{userId}}
Authorization: Bearer {{apiKey}}
```

#### 환경 변수

```http
# 환경 변수 사용 (.env 파일 또는 시스템 환경 변수)
GET {{env.API_URL}}/users
Authorization: Bearer {{env.API_TOKEN}}

# 조건부 환경 설정
@baseUrl = {{env.NODE_ENV == "production" ? "https://api.prod.com" : "https://api.dev.com"}}
```

#### 인증 방법

```http
# Basic Auth
GET https://api.example.com/secure
Authorization: Basic dXNlcjpwYXNzd29yZA==

# Bearer Token
GET https://api.example.com/protected
Authorization: Bearer {{token}}

# API Key in Header
GET https://api.example.com/data
X-API-Key: {{apiKey}}

# API Key in Query
GET https://api.example.com/data?api_key={{apiKey}}
```

#### 폼 데이터 및 파일 업로드

```http
# Form URL Encoded
POST https://api.example.com/login
Content-Type: application/x-www-form-urlencoded

username=user&password=pass

###

# Multipart Form Data
POST https://api.example.com/upload
Content-Type: multipart/form-data; boundary=boundary123

--boundary123
Content-Disposition: form-data; name="title"

My File Title
--boundary123
Content-Disposition: form-data; name="file"; filename="example.txt"
Content-Type: text/plain

< ./files/example.txt
--boundary123--

###

# 파일 읽기 (< 문법)
POST https://api.example.com/data
Content-Type: application/json

< ./data.json
```

#### 응답 처리

```http
# JQ를 사용한 응답 필터링
# @jq .data.users[0].name
GET https://api.example.com/users

###

# 응답을 파일로 저장
# @save response.json
GET https://api.example.com/users

###

# 응답에서 변수 추출
# @variable token = .access_token
POST https://api.example.com/auth/login
Content-Type: application/json

{
  "username": "user",
  "password": "pass"
}
```

#### 고급 기능

```http
# 프리스크립트 (요청 전 실행)
# @pre-request
# console.log("Before request");

# 포스트스크립트 (응답 후 실행)  
# @post-response
# console.log("After response");

# 테스트 검증
# @test
# pm.test("Status is 200", () => {
#   pm.expect(pm.response.code).to.equal(200);
# });

GET https://api.example.com/users

###

# GraphQL 요청
POST https://api.example.com/graphql
Content-Type: application/json

{
  "query": "query GetUsers { users { id name email } }"
}

###

# 커스텀 cURL 플래그
# @curl --connect-timeout 30
GET https://slow-api.example.com/data
```

#### 환경 파일 (.http-client.env.json)

```json
{
  "development": {
    "baseUrl": "http://localhost:3000",
    "apiKey": "dev-key"
  },
  "production": {
    "baseUrl": "https://api.production.com",
    "apiKey": "prod-key"
  }
}
```

#### 사용 팁

1. **파일 구조**: 관련 요청들을 하나의 .http 파일에 모아서 관리
2. **변수 활용**: 자주 사용하는 URL, 토큰 등은 변수로 정의
3. **환경 분리**: 개발/스테이징/프로덕션 환경별로 변수 파일 분리
4. **응답 검증**: @jq를 활용하여 응답 데이터 확인
5. **파일 분할**: 기능별로 .http 파일을 나누어 관리


- Translate mixed Korean-English instruction into proper English.
