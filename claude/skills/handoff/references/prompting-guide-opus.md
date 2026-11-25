# 프롬프팅 가이드 요약: Claude Opus 5.5 (handoff에 쓰는 부분)

출처: claude-api skill(번들 2.1.330)의 `shared/model-migration.md`에 있는 두 절입니다. 하나는 "Migrating to Claude Opus 5.5"이고, 다른 하나는 그 절이 출발점으로 가리키는 "Migrating to Claude Opus 5 → Behavioral shifts"입니다. 2026-11-23에 확인했습니다. `shared/live-sources.md`에는 Opus 5.5 전용 Prompting 페이지가 없습니다. 가이드는 "Claude Opus 5의 프롬프팅 패턴이 합리적인 출발점"이라고 적고 있습니다. 전용 페이지가 생기면 이 파일을 다시 확인합니다.

별칭 `opus` → `claude-opus-5-5`.

## 템플릿과 다르게 쓸 곳

템플릿(`handoff-template.md`)의 공통 절은 Fable 5.2 가이드를 기준으로 썼습니다. Opus 5.5로 넘길 때는 절마다 다음과 같이 다룹니다.

| 공통 절 | Opus 5.5에서 | 근거 |
|---|---|---|
| effort | **값을 꼭 적습니다.** API 기본값은 `medium`입니다. Fable과 이전 Opus의 기본값은 `high`였습니다. 출발점은 `medium`으로 두고, 어렵거나 오래 혼자 도는 일은 `high`로 올립니다. `xhigh`와 `max`는 효과가 확인된 일에만 씁니다. 같은 이름의 effort라도 Opus 5보다 생각을 더 합니다 | "default is medium", "medium exceeds Opus 5 at high", "tends to think more per turn" |
| 생각을 줄이고 싶을 때 | "덜 생각하라" 같은 문장을 넣지 않고 **effort를 낮춥니다** | "lower the effort level before adding think less instructions" |
| 토큰·비용 예산 | 템플릿 문구를 그대로 둡니다. 토큰 수를 목표로 주지 않는다는 원칙은 Opus 가이드에서 확인하지 못했습니다(추정). 다만 지켜서 손해 볼 것은 없습니다 | 확인하지 못함 |
| 서브에이전트 | 템플릿 문구(비용부터 말함, 쓸 때와 쓰지 않을 때를 가름, 최대 N개)를 그대로 둡니다. Opus 5 계열은 서브에이전트를 쉽게 띄우므로 **최대 개수를 숫자로 꼭 적습니다**. "검토나 검증에 서브에이전트를 쓰지 않는다"는 문장을 빼지 않습니다 | "Delegates to subagents more readily", "A deterministic ceiling on spawn count is the reliable lever" |
| 끝까지 하기 | 템플릿 문구에 **범위 문장**을 한 줄 더합니다. "요청한 범위 그대로 합니다. 요청이 틀렸거나 더 나은 길이 있다고 보면 한 문장으로 말하고, 요청대로 계속합니다. 조용히 좁히거나 넓히거나 바꾸지 않습니다." | "Task scope expansion" 절의 권고 문구 |
| 자기 검증 지시 | 할 일 절에 "다시 확인하라", "마지막에 검증 단계를 두라"를 넣지 않습니다. 이 모델은 시키지 않아도 스스로 검증하므로, 그런 문구는 과잉 검증을 부릅니다. 다만 템플릿의 "돌아온 서브에이전트 결과는 몇 건 원문과 대조" 문장은 남깁니다. 이것은 자기 검증이 아니라 받은 결과를 확인하는 일입니다 | "Over-verification - delete your verification scaffolding", "Self-check instructions are the same trap" |
| 승인과 주의 | 템플릿 문구를 그대로 둡니다. Opus 쪽에 따로 정한 권고는 찾지 못했습니다 | 확인하지 못함 |
| 글쓰기 방식(보고서) | 템플릿 문구를 그대로 둡니다. 가이드의 "Communicating with the user" 권고와 방향이 같습니다. 디스크에 쓰는 문서가 길어지는 경향이 있으므로 결과물 절에 **분량**을 꼭 적습니다 | "Longer written deliverables", Opus 5.5의 "clearer prose" |

## 이 모델을 고를 만한 일

- 실제 코드베이스에서 여러 단계로 바꾸고 테스트를 통과시키는 일, 코드 리뷰. 가이드는 `medium`에서 Opus 5의 `high`와 같거나 나은 결과를 냈고, 토큰은 절반쯤 썼다고 적고 있습니다.
- 근거가 있는 분석과 보고. 가이드는 Opus 5보다 입력에 없는 수치나 출처를 덜 지어낸다고 적고 있습니다.
- 차트, 다이어그램, 스크린샷 읽기.
- 가격은 Fable 5.2의 절반입니다($4 / $20, Fable은 $8 / $40).
