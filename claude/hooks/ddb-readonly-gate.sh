#!/bin/sh
# PreToolUse hook: DynamoDB 쓰기 명령 차단 — 읽기 전용만 허용
#
# 허용: dy list, dy desc, dy get, dy query, dy scan, aws-vault exec/list
# 차단: dy put, dy del, dy upd, dy bwrite, aws dynamodb
#
# stdin: JSON { "tool_name": "Bash", "tool_input": { "command": "..." } }
# stdout: JSON { "decision": "approve"|"deny", "reason": "..." }

set -e

INPUT=$(cat)

COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")

# aws dynamodb 직접 호출 차단 (dy CLI만 허용)
case "$COMMAND" in
  *"aws dynamodb"*|*"aws --region"*dynamodb*)
    echo '{"decision":"deny","reason":"aws dynamodb 직접 호출은 차단됩니다. dy CLI를 사용하세요."}'
    exit 0
    ;;
esac

# dy 쓰기 명령 차단
case "$COMMAND" in
  *"dy put"*|*"dy del"*|*"dy upd"*|*"dy bwrite"*|*"dy admin"*|*"dy bootstrap"*|*"dy import"*|*"dy export"*|*"dy backup"*|*"dy restore"*)
    echo '{"decision":"deny","reason":"dy 쓰기/관리 명령은 차단됩니다. 읽기 전용 명령만 허용: list, desc, get, query, scan"}'
    exit 0
    ;;
esac

echo '{"decision":"approve"}'
