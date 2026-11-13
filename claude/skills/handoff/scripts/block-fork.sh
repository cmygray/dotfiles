#!/bin/zsh
# PreToolUse hook (matcher: Agent). handoff 세션에서 fork 서브에이전트를 막는다.
# fork는 CLAUDE_CODE_SUBAGENT_MODEL_FORCE를 무시하고 부모 모델(Fable)을 그대로 쓰기 때문이다.
input=$(cat)
if [[ $(print -r -- "$input" | jq -r '.tool_input.subagent_type // ""') == "fork" ]]; then
  print -u2 "이 세션에서는 fork 서브에이전트를 쓰지 않습니다. fork는 부모 모델(Fable)로 돌아 비용이 큽니다. subagent_type을 general-purpose나 Explore로 바꾸고, 브리프에 필요한 맥락을 직접 적어 다시 호출하십시오."
  exit 2
fi
exit 0
