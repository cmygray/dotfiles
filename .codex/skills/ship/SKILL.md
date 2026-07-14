---
name: ship
description: GitHub 이슈나 Notion 태스크 하나를 구현하고 로컬 검증, PR, checks, merge, stag 검증, Slack 알림까지 배송한다. "/ship 이슈-URL", "$ship", "이거 배송해줘", "이슈 처리해서 stag까지", 기존 ship PR 재개 요청에 사용한다.
---

# Ship

먼저 [references/playbook.md](references/playbook.md)와
[references/repo-profiles.md](references/repo-profiles.md)를 모두 읽는다. playbook을 절차의 단일
정본으로, repo profile을 레포별 실행 사실로 취급한다. 이 파일은 Codex 배선만 정의한다.

## 호출

```text
/ship <issue-or-task-url> [reviewer=<id>] [label=<name>] [notify=<#channel>] [mention=<@who,...>] [until=<stage>]
```

- 인자 오버라이드가 없으면 profile 기본값을 사용한다.
- `until=pr`이면 stage 6의 PR 생성과 metadata 적용 뒤 멈춘다. checks까지면 `until=checks`를 사용한다.
- target이 기존 PR이면 PR 본문의 검증 리포트와 현재 HEAD/checks로 완료 스테이지를 복원한다.

## Codex 배선

playbook stage 0-9를 순서대로 실행한다. stage 0의 worktree root는
`.codex/worktrees/<task-slug>`이다.

| 역할 | Codex 실행 |
|---|---|
| stage 4 로컬 앱 기동 | `runner` custom agent에 정확한 worktree를 넘긴다. ai-learning은 `up --namespace ai-learning <worktree>`, Storybook은 `up --script storybook <worktree>`를 사용한다. |
| stage 4, 8 AC 검증 | `verifier` custom agent에 AC 전체를 전달한다. 로컬은 환경 manifest와 worktree, stag은 PR URL과 쓰기 허용 범위를 전달한다. |
| stage 7 checks 감시 | 짧으면 메인에서 `gh pr checks --watch`; 오래 걸리거나 merge/deploy 추적이 필요하면 `babysit` custom agent에 PR URL, `merge=<profile merge>`, `stag-workflow="<profile deploy.stag_workflow>"`를 위임한다. |
| 나머지 stage | 메인 task에서 직접 수행한다. 구현은 한 agent가 소유하게 하여 동시 편집 충돌을 만들지 않는다. |

`runner`, `verifier`, `babysit` named custom agent 파일은 비용 효율 모델을 고정한다. 사용자 요청이
없는 한 primary agent의 고비용 모델로 override하지 않는다. custom agent 선택을 노출하지 않는
surface에서는 모델을 고정할 수 없는 generic subagent로 대체하지 말고 인라인 수행한다.

위임 프롬프트에는 다음을 반드시 포함한다.

- 입력: target, worktree/PR, profile, AC, 허용된 환경과 쓰기 범위
- 완료 조건: 핵심 결과를 최종 메시지로 반환
- 필수 결과: runner는 URL/port/health, verifier는 AC별 punch list/evidence, babysit은 checks/review/merge/deploy 상태와 blocker
- 실패 규칙: 추측하거나 우회하지 말고 실제 오류와 재현 명령을 반환

agent가 회신 없이 idle이면 한 번 결과를 요청한다. 그래도 없으면 `ct app list`, `gh pr view`,
`gh pr checks`로 산출물을 직접 조회해 진행한다.

## 도구

preflight에서 필요한 도구를 실제로 확인한다.

- GitHub 이슈, PR, checks, workflow: `gh` CLI를 사용하고 repo PR template을 준수한다.
- Classting 로컬 실행, 토큰, API: `ct app`, `ct auth`, `ct apis`를 사용한다. AWS가 필요하면 항상 `aws-vault exec <profile> -- <cmd>`를 사용한다.
- UI evidence: `agent-browser` skill/CLI를 사용한다. browser를 직접 쓰기 전에 해당 skill을 읽는다.
- Notion target: 설치된 `notion` skill/connector로 본문과 링크 문서를 읽는다. 접근할 수 없으면 AC를 추측하지 않는다.
- Slack 알림: 설치된 `slack-outgoing-message` workflow를 사용한다. channel과 mention이 인자나 profile로 확정된 경우에만 stage 9에서 전송한다.
- 장시간 감시: 현재 surface의 Codex automation 도구가 있으면 `babysit`이 사용한다. 등록 여부를 확인하지 못하면 감시 중이라고 보고하지 않는다.

`gh`, `ct`, 필요한 auth/env file, UI 도구 중 현재 plan에 필요한 항목이 없으면 stage 0에서 멈추고
빠진 항목과 확인 명령을 정확히 보고한다.

## 상태와 안전

- 각 stage 뒤에 `stage`, 핵심 결과, 다음 stage를 한 줄로 남긴다.
- plan의 AC matrix와 `verified_head`를 대화 및 PR 검증 리포트에 유지한다.
- HEAD가 바뀌면 기존 evidence를 stale로 취급하고 영향받는 AC를 merge 전에 재검증한다.
- `NOT COVERED`를 숨기지 않는다. 대화형이면 진행 여부를 묻고, 처음부터 merge까지 위임받았으면 PR 본문과 최종 보고에 명시한다.
- no-merge 정책에서는 checks green, reviewer 요청, 가능한 auto-merge 설정까지 수행한 뒤 stage 8-9가 남았다고 보고한다.
- 기본 브랜치 direct push, force-push, profile이 금지한 실행 경로, singleton stack 강제 점유를 금지한다.
- 같은 실패가 두 번 반복되면 원인, 시도한 조치, 남은 선택지를 보고하고 멈춘다.
