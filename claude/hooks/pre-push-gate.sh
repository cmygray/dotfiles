#!/bin/sh
# PreToolUse hook: git push 전에 프로젝트의 lint/test 게이트 통과 강제
#
# stdin: JSON { "tool_name": "Bash", "tool_input": { "command": "..." } }
# stdout: JSON { "decision": "approve"|"deny", "reason": "..." }

set -e

INPUT=$(cat)

# Bash 도구의 command 필드 추출
COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")

# git push 명령이 아니면 통과
case "$COMMAND" in
  *"git push"*) ;;
  *) echo '{"decision":"approve"}'; exit 0 ;;
esac

# 현재 디렉토리에서 프로젝트 루트 탐지
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
if [ -z "$PROJECT_ROOT" ]; then
  echo '{"decision":"approve"}'
  exit 0
fi

# 게이트 명령어 탐지 및 실행
GATE_FAILED=""

# package.json 기반 (Node.js 프로젝트)
if [ -f "$PROJECT_ROOT/package.json" ]; then
  HAS_LINT=$(python3 -c "import json; d=json.load(open('$PROJECT_ROOT/package.json')); print('yes' if 'lint' in d.get('scripts',{}) else 'no')" 2>/dev/null || echo "no")
  HAS_TEST=$(python3 -c "import json; d=json.load(open('$PROJECT_ROOT/package.json')); print('yes' if 'test' in d.get('scripts',{}) else 'no')" 2>/dev/null || echo "no")

  # 패키지 매니저 탐지
  PKG_MGR="npm"
  [ -f "$PROJECT_ROOT/pnpm-lock.yaml" ] && PKG_MGR="pnpm"
  [ -f "$PROJECT_ROOT/yarn.lock" ] && PKG_MGR="yarn"
  [ -f "$PROJECT_ROOT/bun.lockb" ] && PKG_MGR="bun"

  if [ "$HAS_LINT" = "yes" ]; then
    if ! (cd "$PROJECT_ROOT" && $PKG_MGR run lint 2>&1); then
      GATE_FAILED="lint 실패 ($PKG_MGR run lint)"
    fi
  fi

  if [ -z "$GATE_FAILED" ] && [ "$HAS_TEST" = "yes" ]; then
    if ! (cd "$PROJECT_ROOT" && $PKG_MGR run test 2>&1); then
      GATE_FAILED="test 실패 ($PKG_MGR run test)"
    fi
  fi
fi

# Makefile 기반
if [ -z "$GATE_FAILED" ] && [ -f "$PROJECT_ROOT/Makefile" ]; then
  if grep -q "^lint:" "$PROJECT_ROOT/Makefile"; then
    if ! (cd "$PROJECT_ROOT" && make lint 2>&1); then
      GATE_FAILED="lint 실패 (make lint)"
    fi
  fi
  if [ -z "$GATE_FAILED" ] && grep -q "^test:" "$PROJECT_ROOT/Makefile"; then
    if ! (cd "$PROJECT_ROOT" && make test 2>&1); then
      GATE_FAILED="test 실패 (make test)"
    fi
  fi
fi

if [ -n "$GATE_FAILED" ]; then
  # JSON 안전하게 이스케이프
  REASON=$(echo "$GATE_FAILED" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read().strip()))" 2>/dev/null || echo "\"gate failed\"")
  echo "{\"decision\":\"deny\",\"reason\":$REASON}"
  exit 0
fi

echo '{"decision":"approve"}'
