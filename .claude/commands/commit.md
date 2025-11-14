# 커밋 생성 워크플로우

## 실행 지침

이 커맨드가 호출되면:

### 1. 현재 Git 상태 확인
- `git status` - staged/unstaged changes 확인
- staged changes가 없으면 사용자에게 안내 후 종료
- `git log --pretty=format:"%s" -10` - 최근 10개 커밋 메시지 수집

### 2. 커밋 스타일 감지/선택
- 최근 10개 커밋 메시지 분석:
  - `type(scope):` 또는 `type:` 패턴이 과반수면 → Conventional Commits
  - 그 외 → Chris Beams style
- 감지된 스타일을 사용자에게 알리고 변경 원하는지 확인
- 감지 실패 시 사용자에게 선택 요청:
  - `1. Conventional Commits`
  - `2. Chris Beams style`

### 3. Staged Changes 분석 및 논리적 단위 분할
- `git diff --cached --stat` - 변경된 파일 목록
- `git diff --cached` - 상세 변경 내역
- 변경사항을 논리적 단위로 그룹핑:
  - 예: 기능 추가 / 버그 수정 / 리팩토링 / 테스트 / 문서 등
  - 파일 간 연관성, 변경 목적, 작업 흐름 고려
- **여러 개로 나누는 것이 합리적인 경우**:
  - 사용자에게 제안: "다음과 같이 N개의 커밋으로 나누는 것을 제안합니다:"
  - 각 커밋의 범위와 목적 설명
  - 사용자 동의 획득
- **하나의 커밋이 적절한 경우**:
  - 단일 커밋으로 진행

### 4. 커밋 메시지 초안 작성

#### Conventional Commits 스타일
```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**구성 요소:**
- **type**: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`, `ci`, `build`, `revert`
- **scope**: 변경 범위 (영어, 선택사항)
- **description**: 변경사항 요약 (한글, 50자 이하 권장)
- **body**: 무엇을, 왜 변경했는지 상세 설명 (한글, 선택사항)
- **footer**:
  - `BREAKING CHANGE:` - 중대한 변경사항 (한글 설명)
  - `Fixes #123` / `Closes #456` - 이슈 참조
  - `Co-Authored-By: Claude <noreply@anthropic.com>` - 에이전트 작성 명시

**예시:**
```
feat(auth): JWT 토큰 검증 기능 추가

토큰 만료 검사 및 갱신 로직을 구현하여
인증 플로우의 보안을 개선했습니다.

BREAKING CHANGE: 인증 토큰이 이제 1시간 후 만료됩니다
Fixes #456

Co-Authored-By: Claude <noreply@anthropic.com>
```

#### Chris Beams Style
```
<제목: 50자 이내, 명령형, 대문자 시작, 마침표 없음>

<본문: 72자마다 줄바꿈, 무엇을/왜 설명>

<푸터: 이슈 참조, 에이전트 작성 명시>
```

**예시:**
```
JWT 토큰 검증 기능 추가

토큰 만료 검사 및 갱신 로직을 구현했습니다. 이전에는 토큰이
무제한으로 유효했지만, 이제 1시간 후 자동으로 만료되어 보안이
개선됩니다.

이 변경으로 인해:
 - 토큰 유효성 검사가 매 요청마다 수행됩니다
 - 만료된 토큰은 자동으로 갱신됩니다
 - 리프레시 토큰 메커니즘이 추가되었습니다

Fixes #456

Co-Authored-By: Claude <noreply@anthropic.com>
```

### 5. 이슈 연결 확인
- 커밋과 연결할 이슈가 명확하지 않으면 사용자에게 질문:
  - "이 커밋과 연결할 이슈 번호가 있나요? (예: #123, 없으면 skip)"
- 이슈 번호 제공 시 footer에 추가:
  - `Fixes #123` (이슈 해결)
  - `Closes #123` (이슈 완료)
  - `Refs #123` (이슈 참조만)

### 6. 사용자 확인 및 수정
- 작성된 커밋 메시지(들) 초안을 보여주기
- 여러 커밋인 경우 각 커밋의 순서와 내용 명시
- 수정 요청 시 반영
- 최종 승인 받기

### 7. 커밋 실행
- **여러 커밋인 경우**:
  - 각 논리적 단위별로 파일 staging
  - `git reset` 사용하여 필요한 파일만 선택적으로 staged 상태로 유지
  - 순차적으로 커밋 실행
- **signoff 필수**: `git commit --signoff -m "<메시지>"`
- 여러 줄 메시지는 heredoc 사용:
  ```bash
  git commit --signoff -m "$(cat <<'EOF'
  제목

  본문

  푸터
  EOF
  )"
  ```
- 각 커밋 성공 시 커밋 해시와 요약 표시

## 핵심 원칙

### 커밋 분할 기준
- ✅ **좋은 분할**: 각 커밋이 독립적이고 뚜렷한 목적을 가짐
  - 예: "로그인 API 추가" + "로그인 UI 구현" + "로그인 테스트 추가"
- ❌ **나쁜 분할**: 의미 없이 파일별로 쪼갬
  - 예: "A.ts 수정" + "B.ts 수정" + "C.ts 수정"

### 작업 흐름과 논리적 순서
- 각 커밋은 프로젝트 히스토리를 이해하는데 도움이 되어야 함
- 순서: 기반 작업 → 핵심 기능 → 테스트 → 문서
- 각 커밋 시점에서 빌드가 깨지지 않도록 고려

### 한글 작성 원칙
- type, scope는 영어
- description, body의 주요 내용은 한글
- 기술 용어는 영어 유지 가능 (예: JWT, API, OAuth)

### 에이전트 작성 명시
- 모든 커밋 footer에 반드시 포함:
  ```
  Co-Authored-By: Claude <noreply@anthropic.com>
  ```
- Conventional Commits, Chris Beams 스타일 모두 동일

## 에러 처리

- staged changes 없음 → 안내 후 종료
- git 명령어 실패 → 에러 메시지 표시 및 원인 설명
- 커밋 충돌/문제 → 사용자에게 수동 해결 요청

## 주의사항

- Nushell 환경이므로 `;` 사용 (not `&&`)
- git signoff 필수 (`--signoff`)
- 커밋 메시지에 이모지 사용 안 함 (사용자 명시적 요청 시에만)
- 여러 커밋 생성 시 순서 중요 - 논리적 흐름 유지

## Git 설정 확인

- 커밋 전 `git config user.name`, `git config user.email` 확인
- 설정 안 되어 있으면 사용자에게 안내
