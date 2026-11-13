# 공식 프롬프팅 가이드 요약 (handoff에 쓰는 부분)

출처: Anthropic 「Prompting Claude Fable 5.2」
https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-2.md
(claude-api skill의 `shared/model-migration.md` → Migrating to Claude Fable 5.2, 2026-11 기준으로 확인했습니다. 대상 모델이 바뀌면 같은 skill의 `shared/live-sources.md`에서 그 모델의 Prompting 페이지를 찾아 다시 확인합니다.)

## effort

- `low`: 잘 정의된 짧은 일, 빠른 서브에이전트
- `medium`: 대화형 코딩, 일상적인 지식 작업
- `high`(Fable 5.2 기본값): 어려운 코딩·조사·에이전트 작업, 오래 혼자 도는 일. 대부분의 향상은 high에서 나옵니다.
- `xhigh`: 향상이 측정된 가장 어려운 장기 작업에만
- `max`: 상한을 재 보거나 시간과 토큰이 상관없는 드문 일

낮은 effort일수록 일을 덜 끝내고 멈추기 쉽습니다. low나 medium으로 넘기면 「끝까지 하기」 절이 꼭 필요합니다. effort는 답의 길이를 거의 바꾸지 않습니다. 길이는 프롬프트로 정합니다. 「깊이 생각하지 말고 답하라」 같은 문장은 medium 이상에서 듣지 않으므로, 덜 생각하게 하려면 effort를 낮춥니다.

## 토큰 예산

**모델에게 보이는 큰 토큰 예산 문구는 오히려 쓰는 양을 늘릴 수 있습니다.** high·xhigh 코딩 과제에서 큰 예산 문구를 빼자 같은 성능에 비용이 내려갔습니다. 그래서 handoff의 예산 절은 「쓸 수 있는 돈(유료 API)과 멈출 지점, 서브에이전트 수」를 정하고, 생각할 토큰 수를 목표로 주지 않습니다. (API의 `task_budget` 기능은 이 실험에 포함되지 않았고, Claude Code 세션에는 해당하지 않습니다.)

## 서브에이전트

- 위임 정도는 하네스가 정합니다. 프롬프트가 위임을 권하면 쉽게 위임하고, xhigh·max에서는 자기 작업 검토에도 서브에이전트를 씁니다.
- 서브에이전트는 세션 비용의 큰 몫이 될 수 있습니다. 위임 문구는 **비용을 먼저** 말하고, 언제 가치가 있고 언제 없는지, 어떻게 브리프하는지를 씁니다. 이렇게 쓴 설명은 같은 성공률에서 위임을 약 1/3 줄였습니다.
- 비용 문장이 위임을 억제합니다. 너무 적게 위임하면 비용 문장을 줄이고, 너무 많이 하면 늘립니다.

## 끝까지 하기

긴 다단계 작업에서 일이 끝나기 전에 턴을 끝내는 경우가 있습니다(남은 일 목록, 계속할지 묻기, 시간 초과 같은 흔한 장애물에서 멈춤). 가이드 원문 문구:

> Please avoid stopping while you still owe work the user asked for. Be persistent and do not stop unless needed. While status notes are welcome, as is clarifying with the user on open decisions, carry on with work that does not depend on the user's answer without unnecessary stops. If you notice yourself inviting the user to redirect you or offering to wait, instead proceed on the next part of the task. You may meet ordinary obstacles like errors, timeouts, locked files, empty results or failing tools. Diagnose them first, and when they are not real blockers, work through them with the access you have (wait and retry, fix the request, use another tool or source) rather than stopping unnecessarily. If someone clearly decided something is a hard blocker, such as a file marked not to be touched, access that was intentionally withheld, or a safety guardrail, leave it alone, say plainly what you found, and look for another safe way to finish the task. Stopping before the task is complete is very rarely merited - as in when the task can't move forward without user input, or where the blocker is deliberate and should not be worked past. This does not override the need for confirmation on risky or destructive actions.

템플릿의 「끝까지 하기」 절은 이 문구를 한국어로 옮기고 handoff 맥락(원은 지켜보지 않음, 「근거 없음」 표시)을 더한 것입니다.

## 승인과 쌓인 주의

- 「~하지 말 것」 규칙과 이전 세션의 노트가 쌓이면 필요 없는 승인을 구하거나 일상 작업을 멈춥니다.
- **허락 없이 해도 되는 단계를 이름으로 적습니다.** 「더 자유롭게 하라」 같은 일반 지시는 효과가 없었습니다.
- **예외는 규칙 문장 안에 씁니다.** 「절대 X 하지 말 것」 아래에 따로 「승인된 X는 해도 된다」를 두면 거의 따르지 않았습니다. 「X는 먼저 허락을 받는다」로 쓰면 따랐습니다.
- 이유가 사라진 노트와 주의 문구는 지웁니다. 남기는 절대 규칙에는 범위와 이유를 붙입니다.
- 위험하거나 되돌리기 어려운 일의 확인 단계는 남깁니다.

## 보고서(handoff-back)

최종 보고와 핸드오프용 문구(가이드 원문의 요지): 맥락이 없는 유능한 독자를 위해 씁니다. 독자는 도구 호출도 연 파일도 보지 않았습니다. 핵심을 처음 몇 문장에 둡니다. 뒤에서야 설명되는 말을 앞에 쓰지 않습니다. 작업 중에 만든 용어를 쓰지 않습니다. 짧은 문장, 한 문장에 한 생각, 능동태, 같은 것에는 같은 말. 이어지는 생각은 줄글, 따로 떨어진 항목만 목록.

「한 문장 20단어 이하」 같은 딱딱한 문체 규칙은 너무 잘 따라서 글이 끊깁니다. 필요 없으면 넣지 않습니다.
