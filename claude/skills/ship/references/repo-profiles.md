# Repo Profiles — /ship 레포 사실 시트 (v1)

레포별로 달라지는 사실만 이 파일에 둔다. 절차는 [playbook.md](playbook.md)가 정본이다.
스키마가 안정되면 각 레포의 `.claude/harness.yaml`로 졸업시킨다(그때 이 파일은 포인터만 남긴다).

표기: ⚠️ = 아직 실측으로 닫지 못한 값. 사용 전 해당 레포에서 확인하고 이 파일을 갱신할 것.

## minerva-api (ai-learning backend)

```yaml
default_branch: master
workdir: ai-learning/                            # gates, artifacts, 코드 작업 기준
run:
  cwd: ./                                        # ct namespace 탐색은 레포 worktree 루트 기준
  local: ct app start --namespace ai-learning   # worktree 루트에서. docker compose preview stack
  base_url: http://localhost:5001               # master f061d009부터 5001 (3000은 ct app 프록시와 충돌)
  health: GET /health                           # prefix 없음 — /v3/health 는 404
  singleton: true                               # 고정 포트(5001/9000/4566) — 태스크 간 mutex
  forbidden: 직접 `nest start` 실행·검증 금지 — repo .env가 stag RDS를 가리킬 수 있음
  env_files: [ai-learning/.env, ai-learning/infra/.env.preview.local]  # root 체크아웃 → worktree 복사
  fallback: 이미지 rebuild가 Docker Hub 메타데이터 pull에서 hang하면, override yaml로 worktree의
    ai-learning/ 을 /home/node/app 에 bind mount 후 `up -d --no-build --force-recreate ai_learning`
    (--no-deps 없이 하면 mysql까지 recreate되어 로컬 DB 초기화됨)
auth:
  local_token: ct auth token get teacher --env stag --format raw | tail -n 1   # 로컬 컨테이너도 stag 연동
verify:
  modes: [http-sequence, db-migration]
  db_access: docker exec infra-mysql-1 sh -c "MYSQL_PWD=local mysql -uroot minerva_test -N -e '<SQL>'"
  seed_discovery: GET /v3/users/me/ai_assignments?per_page=10&page=1   # per_page/page 필수
envs:
  dev: null                                     # ct apis에 ai-learning dev URL 없음 → dev 스테이지 스킵
  stag: https://clapi.classting.net             # ai.classting.net(프론트 CF) 아님, apis.classting.net 아님
deploy:
  stag_workflow: "AI learning Backend to ECS staging deployement"  # workflow name 원문의 typo 유지
gates:
  lint: yarn lint
  test: yarn test
  build: yarn build
  migration_note: 인덱스·제약조건 이름 64자 제한(MySQL). 배포 마이그레이션은 ECS minerva-migration-stag에서
    실행되며 실패 시 GitHub 로그에 상세가 남지 않음 → 로컬 clean DB mig up 게이트 필수
artifacts:
  swagger: mise exec node@20.9.0 -- yarn gen:swagger   # Node 25에서 gen:swagger 깨짐
merge: rebase                                   # merge commit/squash 금지
pr:
  language: ko
  reviewers: [uknowpro]                         # 기본값 — 인자로 오버라이드 가능
notify:
  channel: "#proj-writing"                      # 프로젝트별 오버라이드 가능
```

## ai-web

<!-- 실측: 2026-07-09 /ship 첫 실행 (TASK-4860 → ai-web#7690)에서 확인된 값 반영 -->

```yaml
default_branch: master                          # 실측 — main 아님
run:
  local: ct app start --name <branch>           # Vite, 공용 프록시 뒤 멀티 인스턴스
  storybook: ct app start --name <branch>-storybook --script storybook
  base_url: 프록시 URL만 사용 (ct app이 보고). 인스턴스 전환은 <proxy>/__switch__, 확인은 <proxy>/__debug__
  singleton: false
  env_files: [.env, .env.local]                 # root 체크아웃 → worktree 복사
  env_prereq: export GITHUB_TOKEN=$(gh auth token)   # yarn 커맨드·pre-commit 훅이 요구
auth:
  local_token: ct auth token get teacher --env stag --format raw | tail -n 1
  # 실측: root .env 기준 로컬 앱 API는 stag(clapi.classting.net) 향. ⚠️ .env 구성에 따라 dev를
  # 향할 수도 있으니 기동 후 네트워크 탭/환경변수로 방향을 확인하고 토큰 env를 맞출 것
verify:
  modes: [ui-scenario, http-sequence, storybook-visual]
envs:
  dev: 브랜치 push → dev 자동 배포 (앱: ai.classting.dev ⚠️ 확인 필요)
  stag: https://ai.classting.net                # master 머지 → stag 자동 배포
deploy:
  stag_workflow: "staging-workflow"
gates:
  lint: yarn lint          # eslint — 기존 error 다수로 CI 게이트 아님. 새 error를 만들지 않는 수준으로
  test: yarn test          # vitest (test:unit 스크립트 없음)
  build: NODE_OPTIONS=--max-old-space-size=8192 yarn build   # 힙 상향 없으면 vite build SIGABRT
  ci_blockers: required CI(unit-testing)·REVIEW_REQUIRED·conflict가 실제 merge 블로커
artifacts:
  codegen_note: src의 generated-api.ts는 BE swagger codegen 산출물. 신규 BE API가 미반영이어도
    전체 재생성은 무관 diff를 유발함 — 필요한 타입만 로컬 정의로 구현하고 재생성은 별도 PR로 분리
merge: repo 설정 따름                            # 실측 — 커밋 개별 유지(rebase/merge-commit 계열), squash 아님
pr: { language: ko }
```

## generative-ai-service (writing-service)

```yaml
default_branch: main   # ⚠️ 확인 필요
workdir: writing-service/                        # 모노레포 하위 디렉토리
run:
  local: yarn serve                              # sls offline start --ignoreJWTSignature, DynamoDB local
  base_url: ⚠️ sls offline 포트 확인 필요 (기본 3002 추정)
  singleton: ⚠️ 확인 필요 (DynamoDB local 포트 공유 여부)
auth:
  local_token: 서명 미검증(--ignoreJWTSignature)이라 형식만 맞으면 됨 — stag 토큰 재사용 가능
verify:
  modes: [http-sequence, db-migration]           # migrations/ = DynamoDB 마이그레이션 스크립트
  e2e: yarn test:e2e                             # testcontainers 기반 — verify:local 보조 수단
envs:
  dev: 있음 — 이 레포만 dev 검증 스테이지 수행 (배포 트리거·URL ⚠️ 확인 필요)
  stag: ⚠️ 확인 필요
deploy:
  stag_workflow: "Writing Service Stag"
gates:
  lint: yarn lint
  test: yarn test:unit
  build: yarn build
merge: ⚠️ 확인 필요
pr: { language: ko }
notify:
  channel: "#proj-writing"
```
