#!/bin/sh
# PreToolUse hook: gh pr create 시 이슈 링크 필수
#
# stdin: JSON { "tool_name": "Bash", "tool_input": { "command": "..." } }
# stdout: JSON { "decision": "approve"|"deny", "reason": "..." }

set -e

INPUT=$(cat)

# Bash 도구의 command 필드 추출
COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")

# gh pr create 명령이 아니면 통과
case "$COMMAND" in
  *"gh pr create"*) ;;
  *) echo '{"decision":"approve"}'; exit 0 ;;
esac

# --body 인자에 closes/fixes/resolves # 패턴 확인
if echo "$COMMAND" | grep -qiE '(closes|fixes|resolves)\s+#[0-9]+'; then
  echo '{"decision":"approve"}'
  exit 0
fi

# --body 인자에 GitHub issue URL 패턴 확인
if echo "$COMMAND" | grep -qiE '(closes|fixes|resolves)\s+https://github\.com/'; then
  echo '{"decision":"approve"}'
  exit 0
fi

echo '{"decision":"deny","reason":"gh pr create에 이슈 링크가 없습니다. PR body에 closes #<number>, fixes #<number>, 또는 resolves #<number>를 포함하세요."}'
