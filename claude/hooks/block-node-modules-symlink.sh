#!/bin/sh
# PreToolUse hook: node_modules 심링크 생성만 정밀 차단
#
# worktree의 node_modules를 메인 체크아웃 등으로 심링크하면 `node_modules/.vite`
# optimizeDeps 캐시를 공유하게 되어, 여러 ct app 인스턴스가 서로 캐시를 덮어써
# `Box.js: undefined is not a function` 류 런타임 깨짐이 난다. 각 worktree는
# 자체 node_modules를 가져야 하므로 node_modules 심링크만 막는다.
#
# 허용: 그 외 모든 ln(.env 등 다른 심링크는 무관), node_modules를 안 건드리는 명령
# stdin: JSON { "tool_name": "Bash", "tool_input": { "command": "..." } }
# stdout: deny일 때만 { "decision": "deny", "reason": "..." }; 그 외엔 무출력

set -e

INPUT=$(cat)

COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")

# `ln -s`(심링크 생성)이면서 node_modules를 다루는 경우만 차단
case "$COMMAND" in
  *"ln -s"*node_modules*|*"ln -sf"*node_modules*|*"ln -fs"*node_modules*)
    echo '{"decision":"deny","reason":"node_modules 심링크 금지: worktree는 자체 node_modules를 가져야 합니다(메인으로 심링크 시 .vite 캐시 공유 → 다중 ct app 인스턴스 충돌·Box.js 깨짐). 대신 worktree에서 yarn install로 실제 설치하세요."}'
    exit 0
    ;;
esac

exit 0
