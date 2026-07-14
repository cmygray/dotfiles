---
name: ship
description: 이슈/태스크 URL 하나로 구현→로컬 검증→PR→merge→stag 검증→Slack 알림까지 배송 파이프라인 실행. "/ship <이슈 URL>", "이거 배송해줘", "이슈 처리해서 stag까지" 등의 요청에 반응.
---

# Ship — 이슈에서 stag까지 배송 파이프라인

절차의 정본은 [references/playbook.md](references/playbook.md)이고, 레포별 사실은
[references/repo-profiles.md](references/repo-profiles.md)에 있다. **두 파일을 먼저 읽고 시작한다.**
이 문서는 Claude Code에서의 실행 방법(에이전트 배선)만 정의한다.

## 호출

```
/ship <issue-or-task-url> [reviewer=<id>] [label=<name>] [notify=<#channel>] [mention=<@who,...>] [until=<stage>]
```

- 인자 없이 오버라이드가 없으면 프로파일 기본값을 쓴다.
- `until=pr`처럼 주면 해당 스테이지까지만 진행하고 멈춘다.

## 실행 방법 (Claude Code 배선)

playbook의 스테이지 0–9를 순서대로 실행하되, 다음을 위임한다:

stage 0의 `<harness-worktrees>`는 `.claude/worktrees`로 치환한다.

| playbook 역할 | Claude Code에서 |
|---|---|
| stage 4 로컬 앱 기동 (runner 역할) | **runner 에이전트** 스폰 (`runner up <worktree>` 형식, ai-learning은 `--namespace ai-learning`). 반환된 환경 매니페스트(URL·포트)를 받아 둔다 |
| stage 4·8 AC 검증 (verifier 역할) | **verifier 에이전트** 스폰. 로컬은 매니페스트+plan을, stag은 PR URL을 전달. AC 목록을 그대로 넘겨 punch list를 돌려받는다 |
| stage 7 checks 감시 | 직접 `gh pr checks --watch` 또는 **babysit 에이전트** (장시간이면 babysit 권장) |
| 나머지 스테이지 | 메인 세션에서 직접 수행 |

에이전트 이름은 설치 형태에 따라 `runner`/`verifier` 또는 `dev:runner`/`qa:verifier`일 수 있다.
Agent 도구의 사용 가능 목록에서 찾아 쓰고, 없으면 해당 역할을 인라인으로 수행한다 (Codex 어댑터와 동일 규칙).

**에이전트 회신 규칙**: 스폰 프롬프트에 "완료 시 핵심 결과(URL·포트·punch list·실패 사유)를 최종
메시지로 반환하라"를 반드시 포함한다. 에이전트가 회신 없이 idle로 빠지면 SendMessage로 결과를
요청하고, 그래도 없으면 산출물(ct app list, PR 상태)을 직접 조회해 진행한다 — 기다리며 멈추지 않는다.

## 상태 유지·중단·재개

- 각 스테이지 완료 시 한 줄 상태를 대화에 남긴다 (스테이지명, 핵심 결과, 다음 스테이지).
- plan(AC 매트릭스)과 verified_head는 대화에 명시적으로 기록해 둔다 — 세션이 끊겨도
  이슈·PR·git에서 복원 가능한 것 외에 유일하게 휘발되는 상태다.
- 재개 시: PR이 이미 있으면 본문의 검증 리포트에서 plan과 verified_head를 복원하고,
  현재 HEAD·checks 상태를 보고 이어갈 스테이지를 판정한다.

## 세션 정책과의 상호작용

백그라운드 세션 등 **no-merge 정책** 아래에서는 stage 7(merge)을 직접 수행할 수 없다. 이 경우:

- 사실상 `until=pr`로 동작한다: draft 해제 + checks green + 리뷰 요청까지 진행하고,
  가능하면 auto-merge를 arm한 뒤 "리뷰 승인 대기" 상태로 보고하고 멈춘다.
- stage 8–9(stag 검증·알림)는 merge가 일어난 뒤 별도 호출(`/ship <PR-url>` 재개 또는 babysit)로 잇는다.
- 이 정지는 실패가 아니다 — 최종 보고에 "리뷰 게이트 대기, 남은 스테이지: 8–9"를 명시한다.

## 안전 규칙 (playbook 불변식에 추가)

- 리포트 지점(stage 5)에서 `NOT COVERED`가 남았는데 사용자 지시가 "merge까지"였다면,
  진행하되 PR 본문과 최종 보고에 그 사실을 명시한다. 대화형이면 멈추고 물어본다.
- stage 9(Slack 알림)는 외부 발신이다. 채널·멘션이 인자나 프로파일로 확정된 경우에만 보낸다.
- 이 스킬은 요구사항이 이미 구체적인 이슈를 전제한다. AC를 뽑을 수 없는 이슈면
  `/refine-task`를 먼저 권하고 멈춘다.
- preflight에서 ct CLI·계정·env 파일 등 필요 설정이 없으면 진행하지 말고, 빠진 항목과 확인 명령을
  정확히 보고한다. 존재가 확인되지 않은 setup 문서 경로를 안내하지 않는다.
