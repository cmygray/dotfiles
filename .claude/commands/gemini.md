# Gemini 협동 작업 가이드

## 기본 사용법
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

## File and Directory Inclusion Syntax

Use the `@` syntax to include files and directories in your Gemini prompts. The paths should be relative to WHERE you run the gemini command:

### Examples

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

## 협업 시나리오별 가이드

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

## 협업 모범 사례

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

## When to Use Gemini CLI

Use gemini -p when:
- Analyzing entire codebases or large directories
- Comparing multiple large files
- Need to understand project-wide patterns or architecture
- Current context window is insufficient for the task
- Working with files totaling more than 100KB
- Verifying if specific features, patterns, or security measures are implemented
- Checking for the presence of certain coding patterns across the entire codebase

## 모니터링 및 품질 관리

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

## Important Notes

- Paths in @ syntax are relative to your current working directory when invoking gemini
- The CLI will include file contents directly in the context
- No need for --yolo flag for read-only analysis
- Gemini's context window can handle entire codebases that would overflow Claude's context
- When checking implementations, be specific about what you're looking for to get accurate results

## 주의사항
- 민감한 정보 (API 키, 비밀번호) 포함된 파일 작업 시 주의
- `-y` 모드는 충분한 검토 후 사용
- 대규모 변경 전 반드시 Git 백업 확인
- 샌드박스 모드도 완전히 안전하지 않으므로 중요 작업 전 백업 필수

---

## Execution Instructions for Claude

When this command is invoked:

1. **Analyze the user's request** following this command to understand what analysis they need
2. **Construct appropriate gemini CLI command** with:
   - `-a` flag if codebase-wide analysis needed
   - `-p` flag with user's prompt
   - `@` syntax for specific files/directories if mentioned
3. **Execute the gemini command** using Bash tool
4. **Summarize the results** in a clear, actionable format for the user
5. **Extract key findings** such as:
   - Impact scope
   - Risk areas
   - Recommended changes
   - File/function references

Example workflow:
```
User: /gemini HTTP POST /foo 경로의 영향범위 분석
→ Execute: gemini -a -p "@src/ HTTP POST /foo 엔드포인트의 인터페이스 변경 시 영향받는 모든 코드 위치와 의존성을 식별해줘"
→ Summarize results with specific file:line references
```
