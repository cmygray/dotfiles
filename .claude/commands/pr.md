# Pull Request 생성 워크플로우

## 실행 지침

이 커맨드가 호출되면:

1. **현재 Git 상태 확인**
   - 현재 브랜치 이름
   - base 브랜치 확인 (main/master)
   - 커밋 히스토리 분석
   - 변경된 파일 목록 확인

2. **PR 템플릿 확인**
   - `PULL_REQUEST_TEMPLATE.md` 또는 `.github/PULL_REQUEST_TEMPLATE.md` 존재 여부 확인
   - 템플릿이 있으면 해당 구조 사용
   - 없으면 기본 템플릿 사용

3. **자동 라벨 분석**
   - PR 제목과 커밋 메시지를 분석하여 적절한 라벨 자동 선택
   - 변경된 파일 분석으로 추가 라벨 감지
   - 라벨 매핑 규칙 (아래 참조)

4. **PR 내용 초안 작성**
   - 커밋 메시지와 diff 분석
   - 템플릿 형식에 맞춰 한글로 작성
   - 변경사항 요약
   - 테스트 계획 (있다면)

5. **사용자 확인**
   - 작성된 초안과 선택된 라벨을 보여주고 동의 구하기
   - 수정 요청 시 반영

6. **PR 생성**
   - `gh pr create` 명령어 사용
   - `--assignee cmygray` 플래그로 자동 할당
   - `--label` 플래그로 분석된 라벨 적용
   - 한글 제목과 본문 사용
   - 성공 시 PR URL 반환

## 자동 라벨 매핑 규칙

다음 규칙에 따라 PR 제목, 커밋 메시지, 변경된 파일을 분석하여 라벨을 자동으로 선택하세요:

### 커밋 메시지 및 PR 제목 키워드 기반
- `fix:`, `bugfix`, `hotfix` → **bug**, **fix**
- `feat:`, `feature:` → **feature**, **enhancement**
- `docs:`, `documentation:` → **documentation**
- `chore:`, `build:` → **chore**
- `refactor:`, `style:` → **enhancement**
- `test:`, `tests:` → (테스트 라벨이 있다면 적용)
- `ci:`, `.github/workflows/` 변경 → **ci**
- `perf:`, `performance` → **enhancement**

### 변경 파일 기반
- `package.json`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml` 변경 → (dependencies 라벨이 있다면 적용, 없으면 **chore**)
- `*.md` 파일만 변경 → **documentation**
- `.github/workflows/*.yml` 변경 → **ci**

### 라벨 선택 로직
1. 여러 규칙이 매칭되면 모든 해당 라벨을 적용 (중복 제거)
2. 라벨은 쉼표로 구분하여 `--label` 플래그에 전달
3. 아무 규칙도 매칭되지 않으면 라벨을 지정하지 않음 (사용자가 나중에 추가 가능)
4. 최대 3-4개의 라벨만 자동 선택 (너무 많으면 혼란)

## 기본 템플릿 구조 (템플릿 없을 시)

```markdown
## 변경사항
<!-- 이번 PR에서 변경된 주요 내용을 설명해주세요 -->

## 변경 이유
<!-- 왜 이 변경이 필요한지 설명해주세요 -->

## 테스트 계획
<!-- 어떻게 테스트했는지, 또는 테스트 계획을 설명해주세요 -->
- [ ] 로컬 테스트 완료
- [ ] 단위 테스트 추가/수정

## 체크리스트
- [ ] 코드 리뷰 준비 완료
- [ ] 문서 업데이트 (필요시)
- [ ] 브레이킹 체인지 여부 확인
```

## gh pr create 명령어 예시

```bash
# 자동 할당 및 라벨 적용 예시
gh pr create \
  --title "feat: 새로운 인증 기능 추가" \
  --body "$(cat pr-body.md)" \
  --assignee cmygray \
  --label "feature,enhancement"

# 단일 라벨 예시
gh pr create \
  --title "fix: 로그인 버그 수정" \
  --body "..." \
  --assignee cmygray \
  --label "bug,fix"

# 라벨 없이 (매칭 규칙 없을 경우)
gh pr create \
  --title "기타 변경사항" \
  --body "..." \
  --assignee cmygray
```

## 주의사항

- 커밋이 없는 브랜치는 PR 생성 불가
- base 브랜치가 main이 아닌 경우 명시적으로 지정
- draft PR 필요시 `--draft` 플래그 사용
- GitHub CLI 인증 필요 (`gh auth status`로 확인)
- **자동 할당은 항상 cmygray로 설정**
- 라벨은 저장소에 존재하는 라벨만 사용 가능 (`gh label list`로 확인)

## Git & GitHub 가이드라인

- gh CLI 사용 (웹 인증 문제)
- PR 메시지를 한글로 작성
- PULL_REQUEST_TEMPLATE.md 참고할 것
- 자동 할당과 라벨링을 통해 PR 관리 효율화
