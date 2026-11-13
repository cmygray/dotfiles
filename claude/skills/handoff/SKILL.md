---
name: handoff
description: 다른 세션(옆 Rex 팬의 새 Claude 세션, 주로 Fable)에 일을 넘기는 handoff 문서를 쓰고, 그 세션이 돌려준 handoff-back 문서를 읽어 다음 결정으로 잇는다. "핸드오프", "handoff", "handoff back", "옆 팬에서 fable로", "다른 세션에 넘겨", "핸드오프 프롬프트 써 줘", "handoff-back 읽어 줘" 요청에 사용.
---

# handoff — 다른 세션에 일을 넘기고 돌려받기

메인 세션은 판단과 결정을 맡고, 길고 무거운 작업은 새 세션에 넘깁니다. 두 세션은 서로의 대화를 볼 수 없으므로 디스크의 파일로 주고받습니다.

## 흐름

1. **넘길 일인지 가른다.** 메인 세션에서 몇 번의 도구 호출로 끝나는 일은 넘기지 않습니다. 넘기는 경우는 맥락을 많이 쓰는 조사·구현·실험, 다른 모델이나 effort가 맞는 일, 메인과 나란히 돌릴 일입니다.
2. **결정할 것을 먼저 닫는다.** 넘기기 전에 원이 정해야 할 전제(범위, 비용 상한, 건드리면 안 되는 것)가 있으면 이분법으로 묻고 합의합니다. 합의한 것은 「바뀌지 않는 전제」에 적습니다.
3. **`handoff-<주제>.md`를 쓴다.** 템플릿은 [references/handoff-template.md](references/handoff-template.md)입니다. 공통 절(토큰·비용 예산, 서브에이전트 정책, 끝까지 하기, 글쓰기 방식)은 템플릿 문구를 기본으로 두고 일에 맞게 고칩니다. 쓰기 전에 [references/prompting-guide.md](references/prompting-guide.md)를 읽습니다.
4. **옆 팬에서 새 세션을 띄운다.** 아래 「세션 띄우기」를 따릅니다. 넘기는 말은 한 줄입니다.
5. **돌려받는다.** 작업 세션은 `handoff-back-<주제>.md`를 남깁니다(템플릿: [references/handoff-back-template.md](references/handoff-back-template.md)). 원이 「돌아왔다」고 하거나 파일이 생기면 읽고, 결론과 「원이 지금 정해야 할 것」을 원에게 짧게 전합니다. 결정을 받으면 다음 handoff를 씁니다.

## 파일 이름 규칙

- 넘기는 문서: `handoff-<주제>.md`
- 돌려받는 문서: `handoff-back-<주제>.md` (주제 부분을 같게)
- 작업 세션의 진행 노트: `progress-<주제>.md`
- 위치: 작업 폴더 루트. 폴더가 정해지지 않았으면 원에게 묻습니다.

## 세션 띄우기

`REX_SESSION`이 있을 때 현재 팬 오른쪽에 띄웁니다. 대상 모델과 effort는 handoff 문서 첫 줄과 같게 합니다.

```bash
rex split -s "$REX_SESSION" -b "$REX_BLOCK" --split=right \
  -c <작업 폴더> --label <주제> --json -- \
  claude --model claude-fable-5-2 --effort high \
  --settings ~/dotfiles/claude/skills/handoff/scripts/session-settings.json \
  "<작업 폴더>/handoff-<주제>.md 를 읽고 그대로 수행해 주세요. 끝나면 handoff-back-<주제>.md로 돌려주세요." \
  | jq -r '.block_ids[0]'
```

- **`--settings`는 빼지 않습니다.** 이 설정이 Fable 세션이 Fable 서브에이전트를 띄우는 것을 막습니다(아래 「서브에이전트 모델 고정」).
- 띄운 뒤 `rex capture -s "$REX_SESSION" -b <block> --trim | tail -15`로 시작했는지만 확인합니다. 그 뒤로는 지켜보지 않습니다.
- `REX_SESSION`이 없으면 위 한 줄 프롬프트를 원에게 주고, 원이 직접 세션을 엽니다.
- 같은 대화 맥락이 꼭 필요하면 `claude --resume <id> --fork-session`을 쓸 수 있습니다. 하지만 기본은 새 세션입니다. 넘길 맥락은 handoff 문서에 씁니다.

## 서브에이전트 모델 고정

Claude Code의 서브에이전트는 기본적으로 부모 모델을 이어받습니다. 그래서 Fable 세션이 서브에이전트를 띄우면 Fable로 돌아 비용이 커집니다. 프롬프트 문구만으로는 이를 보장할 수 없어서, 하네스에서 막습니다. `scripts/session-settings.json`이 하는 일은 두 가지입니다.

| 장치 | 효과 |
|---|---|
| `CLAUDE_CODE_SUBAGENT_MODEL=sonnet` + `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` | Agent 호출에 `model`을 지정해도 무시하고 sonnet으로 띄웁니다 |
| PreToolUse hook `scripts/block-fork.sh` | `subagent_type: "fork"`를 막고 다른 타입으로 다시 부르게 합니다. fork는 FORCE를 무시하고 부모 모델을 쓰기 때문입니다 |

2026-11-13에 sonnet 메인 세션으로 실측했습니다.

- FORCE를 켜고 `model: "opus"`로 호출하면 서브에이전트는 haiku(당시 설정값)로 돌았습니다.
- FORCE 없이 같은 호출을 하면 opus로 돌았습니다. 기본값만 두는 것으로는 막을 수 없습니다.
- FORCE를 켜고 fork로 호출하면 부모 모델(sonnet)로 돌았습니다.
- hook을 붙이면 fork가 막혔고, 세션은 general-purpose로 다시 불렀습니다. `model: "opus"`를 지정했지만 sonnet으로 돌았습니다.

서브에이전트에 Fable이 꼭 필요한 일이면 그 handoff만 `CLAUDE_CODE_SUBAGENT_MODEL`을 바꾼 설정 파일로 띄우고, 이유를 handoff의 예산 절에 적습니다.

## handoff를 쓸 때 지킬 것

- **읽는 사람은 맥락이 없는 유능한 동료입니다.** 메인 세션에서 만든 줄임말, 「아까 그거」, 대화 속 결론을 그대로 쓰지 않습니다. 파일 경로와 줄 범위를 적습니다.
- **목표와 이유를 먼저, 방법은 필요한 만큼만.** Fable 5.2 이후 모델은 지시를 촘촘히 따릅니다. 이전 모델용으로 쓴 세세한 절차는 결과를 나쁘게 할 수 있습니다. 판단은 맡기고, 판단 기준과 경계를 줍니다.
- **허락 없이 해도 되는 일을 이름으로 적습니다.** 「신중하게 하라」 같은 일반 지시는 효과가 없습니다. 「승인과 경계」 절에 「묻지 않고 합니다」 목록과 「이 일의 것이 아닙니다」 목록을 둡니다. 금지 규칙에 예외가 있으면 그 규칙 문장 안에 씁니다.
- **낡은 주의 문구를 옮기지 않습니다.** 이전 handoff에서 복사한 「절대 ~하지 말 것」은 이유가 아직 유효한지 확인하고, 남길 때는 범위와 이유를 붙입니다.
- **같이 도는 작업을 적습니다.** 다른 세션이 같은 폴더에서 일하고 있으면 그 결과물을 읽되 고치지 않게 합니다.

## handoff-back을 읽을 때

- 결론이 handoff의 목표에 답하는지 먼저 봅니다. 「보이지 못했다」, 「추정」이라고 쓴 곳은 그대로 원에게 전합니다. 메인 세션이 확인된 것처럼 바꿔 말하지 않습니다.
- 숫자나 근거가 결정에 쓰이면 한두 건을 원문에서 직접 확인합니다.
- 경계를 넘은 변경(고치지 말라고 한 파일, commit, 공유 문서)이 있었는지 `git status`나 파일 시각으로 확인합니다.
