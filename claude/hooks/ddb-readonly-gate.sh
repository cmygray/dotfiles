#!/bin/sh
# PreToolUse hook: DynamoDB 직접 접근 차단 — ddb 래퍼만 허용
#
# 차단 대상:
#   - dy (dynein) 직접 호출
#   - aws dynamodb 직접 호출
#   - aws-vault exec ... dy 직접 호출
#
# stdin: JSON { "tool_name": "Bash", "tool_input": { "command": "..." } }
# stdout: JSON { "decision": "approve"|"deny", "reason": "..." }

set -e

INPUT=$(cat)

COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")

# ddb 래퍼 명령은 허용
case "$COMMAND" in
  ddb\ *|ddb) echo '{"decision":"approve"}'; exit 0 ;;
esac

# dy 직접 호출 차단
case "$COMMAND" in
  dy\ *|*" dy "*|*"aws-vault exec"*dy*)
    echo '{"decision":"deny","reason":"dy 직접 호출은 차단됩니다. ddb 래퍼를 사용하세요. (예: ddb dev query -t table -p key)"}'
    exit 0
    ;;
esac

# aws dynamodb 직접 호출 차단
case "$COMMAND" in
  *"aws dynamodb"*|*"aws --region"*dynamodb*)
    echo '{"decision":"deny","reason":"aws dynamodb 직접 호출은 차단됩니다. ddb 래퍼를 사용하세요. (예: ddb dev query -t table -p key)"}'
    exit 0
    ;;
esac

echo '{"decision":"approve"}'
