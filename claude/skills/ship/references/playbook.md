# Ship Playbook — 이슈에서 stag 검증·알림까지 (하네스 중립 정본)

이 문서는 /ship 파이프라인의 **단일 정본**이다. Claude Code와 Codex의 각 `ship/SKILL.md`는
이 문서를 읽고 실행하는 얇은 어댑터다. 절차를 바꿀 때는 이 파일만 수정한다.

레포별 사실(포트, 실행법, 토큰 환경, 게이트 커맨드)은 [repo-profiles.md](repo-profiles.md)에 있다.
이 문서는 레포 이름을 하드코딩하지 않는다.

## 입력

- `target` (필수): GitHub 이슈 URL 또는 Notion 태스크 URL. 구현할 요구사항의 출처.
- `reviewer=`, `label=`, `notify=`, `mention=` (선택): 프로파일 기본값 오버라이드.
- `until=<stage>` (선택): 해당 스테이지까지만 진행 (예: `until=pr`).
  유효값은 `preflight|plan|implement|gate|verify-local|report|pr|checks|verify-stag|notify`다.

## 불변식 (모든 스테이지에 우선)

1. **sha 핀**: 검증 결과는 항상 `verified_head`(검증 시점 HEAD sha)에 대한 주장이다.
   rebase·amend·리뷰 반영으로 HEAD가 움직이면 기존 검증은 stale — merge 전에 영향 범위를 재검증한다.
2. **약속-입증 대칭**: 검증 보고는 pass/fail 한 마디가 아니라 AC(인수 기준) 단위 커버리지
   매트릭스로 한다. `NOT COVERED`는 숨기지 말고 그대로 드러낸다.
3. **worktree는 소모성 자원**: 태스크의 집이 아니다. merge 후 스테이지는 worktree 없이 동작해야 한다.
4. **기본 브랜치에 직접 push 금지. force-push 금지.** merge는 레포의 merge 방식(프로파일)을 따른다.
5. **로컬 실행·검증은 반드시 프로파일의 방식**으로 한다. 프로파일에 금지된 실행 경로
   (예: 직접 `nest start`)는 어떤 경우에도 쓰지 않는다.
6. 프로파일이 `singleton: true`인 로컬 스택은 태스크 간 mutex다. 다른 인스턴스가 점유 중이면
   실패가 아니라 **대기(blocked)** 로 보고하고 사용자 판단을 구한다.
7. **workdir 준수**: 프로파일에 `workdir`이 있으면(모노레포 하위 디렉토리) gates, artifacts와
   코드 파일 작업을 그 디렉토리 기준으로 한다. `run.cwd`가 별도로 있으면 로컬 앱 기동만 그 경로를
   기준으로 한다.
8. **프로파일 커맨드의 `<branch>` 등 플레이스홀더는 실제 런타임 값으로 치환**해서 실행한다.
   문자 그대로 실행하지 않는다.

## 스테이지

### 0. preflight

- `target`에서 레포와 요구사항 출처를 식별하고 프로파일을 로드한다. 프로파일이 없는 레포면 중단하고 알린다.
- Notion target이면 연결된 GitHub 이슈를 찾아 PR의 `closes|fixes|resolves` 대상으로 기록한다.
  연결 이슈가 없고 issue-link hook이 활성화돼 있으면 GitHub 이슈를 임의 생성하지 말고 preflight에서
  사용자에게 생성 또는 기존 이슈 연결을 요청한다.
- 기본 브랜치를 최신으로 fetch한 뒤 (`git fetch origin <default>`), **origin/<default> 기준의 분리된
  worktree**를 만든다: `git worktree add <harness-worktrees>/<task-slug> -b <branch> origin/<default>`.
  어댑터가 Claude Code에서는 `.claude/worktrees`, Codex에서는 `.codex/worktrees`를
  `<harness-worktrees>`로 정한다. 기존 체크아웃의 브랜치·미커밋 변경은 절대 건드리지 않는다.
  선택한 worktree root가 `git status`에 노출되면 `.git/info/exclude`에 등록한다.
- **이후 모든 코드 탐색·분석도 이 worktree 기준**으로 한다. 메인 체크아웃의 로컬 기본 브랜치는
  stale할 수 있어, 거기서 탐색하면 "코드 없음" 오보가 난다 (탐색 에이전트를 쓸 때 worktree 경로를 명시).
- 프로파일의 `env_files`를 root 체크아웃에서 worktree로 복사한다 (심링크 금지).
- 확인 결과를 한 줄로 보고: base sha, worktree 경로, 브랜치명.

### 1. plan — 검증 계획 수립

- 이슈/태스크 본문(+ 링크된 문서)에서 AC를 추출해 커버리지 매트릭스 초안을 만든다.
  각 AC는 `mode`(http-sequence | ui-scenario | storybook-visual | db-migration) + 구체적 call/route +
  관찰 가능한 evidence를 가져야 한다.
- 구현이 DB 마이그레이션을 포함할 예정이면 **db-migration AC를 자동 추가**한다:
  "clean DB에서 마이그레이션 up 성공 + 식별자(인덱스·제약조건) 길이 ≤ 64자".
- AC를 하나도 구체화할 수 없으면 진행하지 말고 사용자에게 기준을 요청한다 (verifier와 같은 규칙).

### 2. implement

- worktree에서 구현한다. 해당 레포의 CLAUDE.md/AGENTS.md 컨벤션을 따른다.
- 프로파일의 `artifacts`(예: swagger 재생성)를 커밋 전에 갱신한다 — 지정된 커맨드·Node 버전을 그대로 사용.
- 변경을 stage하고 staged diff를 검토한 뒤 커밋한다. 커밋 메시지는 레포 컨벤션(commitlint)을 준수한다.

### 3. gate

- 프로파일의 `gates`(lint / test / build)를 worktree에서 실행한다. 하나라도 실패하면 implement로 돌아간다.
- 결과(각 pass/fail)를 기록해 둔다 — 리포트에 들어간다.

### 4. verify:local

- **runner 역할**: 프로파일의 `run.local` 방식으로 로컬 앱을 띄운다. Claude Code에서는 runner 에이전트를
  스폰하고, 에이전트가 없는 하네스에서는 같은 절차를 인라인 수행한다. 산출은 **환경 매니페스트**:
  `{ base_url, health, token_recipe, db_access, seed_discovery }` — 전부 프로파일에서 온다.
- **verifier 역할**: 매니페스트를 타깃으로 plan의 AC를 하나씩 실행한다. 상태 변화 증거
  (응답 필드 + DB/스토리지 델타 또는 read-back)까지 확인해야 PROVEN이다. 라우트가 응답한다는 사실만으로는
  PROVEN이 아니다.
- db-migration AC는 **clean DB**에서 마이그레이션 up을 실제 실행해 확인한다. 테이블 수동 생성으로
  대체하지 않는다.
- 완료 시 `verified_head`를 기록한다.

### 5. report — 유일한 리포트 지점 (가역/비가역 경계)

아래 형식으로 리포트를 작성한다. 이 리포트가 곧 PR 본문의 검증 섹션이 된다.

```markdown
## 검증 리포트
- verified_head: <sha>
- gates: lint ✅ / test ✅ / build ✅
- local target: <base_url> (<프로파일 run.local 한 줄>)

| AC | mode | 결과 | 증거 |
|----|------|------|------|
| AC-1 <요약> | http-sequence | PROVEN | <응답 발췌·DB 델타> |
| AC-2 <요약> | db-migration | PROVEN | clean DB mig up OK |
| AC-3 <요약> | ui-scenario | NOT COVERED | <사유> |

deviations: <계획과 다르게 한 것, 없으면 "없음">
```

- 대화형 세션이면 리포트를 보여주고 진행 확인을 받는다. 사용자가 처음부터 merge까지 지시한
  파이프라인 실행이면 리포트를 출력하고 계속 진행한다.
- `NOT COVERED`가 남아 있으면 그 사유와 함께 진행 여부를 명시적으로 판단한다 (조용히 통과 금지).

### 6. pr

- 현재 branch를 origin에 push한다. 기본 브랜치 direct push와 force-push는 금지한다.
- 한국어로, 레포에 `.github/PULL_REQUEST_TEMPLATE.md`가 있으면 템플릿을 준수해 작성한다.
  검증 리포트(5)를 본문에 포함한다.
- 프로파일/인자의 assignee·label·reviewer를 적용한다. `gh pr create` 후
  `gh pr edit --add-assignee --add-label` + `gh pr edit --add-reviewer` (또는 create 옵션).

### 7. checks & merge

- 모든 checks가 green이 될 때까지 감시한다. transient 실패는 재시도, 코드 원인 실패는 implement로 back-edge.
- **HEAD가 verified_head와 다르면** (리뷰 반영, rebase) merge 전에 영향받는 AC를 재검증하고
  리포트의 `verified_head`를 갱신한다.
- 레포 프로파일의 merge 방식으로 merge한다.

### 8. verify:stag

- merge commit의 profile `deploy.stag_workflow`가 성공할 때까지 감시한다. profile에 값이 없으면
  해당 merge SHA의 workflow 목록을 보여주고 정확한 대상을 확인받는다. 이름 휴리스틱으로 첫 run을
  고르지 않는다 (마이그레이션 단계 실패 주의 —
  실패 시 워크플로우 로그에 상세가 없을 수 있으니 프로파일의 배포 노트 참고).
- 같은 plan을 stag 타깃(프로파일 `envs.stag`)으로 재실행한다. 읽기 전용 원칙:
  쓰기 검증이 필요한 AC만, plan에 명시된 범위에서 수행한다.
- 결과 punch list를 **PR 코멘트**로 남긴다 (새 리포트를 만들지 않는다).

### 9. notify

- 프로파일/인자의 Slack 채널에 알린다: 이슈·PR 링크, 한 줄 결과, stag 검증 요약, 이해관계자 멘션.
- 알림 전에 채널·멘션 대상이 확정돼 있지 않으면 보내지 말고 사용자에게 확인한다 (외부 발신은 비가역).

## 실패 처리

- 어떤 스테이지든 실패하면: 원인 → 조치 → 검증 구조로 보고하고, 원인이 코드면 implement로,
  환경이면 해당 스테이지 재시도로 back-edge한다.
- 같은 실패가 2회 반복되면 멈추고 사용자에게 상황과 선택지를 보고한다.
