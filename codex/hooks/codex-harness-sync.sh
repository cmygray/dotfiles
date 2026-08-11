#!/bin/bash
# codex-harness-sync — Codex SessionStart hook (개인용)
#
# dev@superct 플러그인의 harness-sync.sh는 `claude plugin ...`만 갱신해서
# Codex 자신의 marketplace 스냅샷은 stale로 남는다 (실측: superct가 2주간
# 7/27 rev에 고정). 이 스크립트가 Codex 쪽 갭을 메운다.
#
# 패턴은 harness-sync.sh와 동일: TTL 스로틀 + 백그라운드 disown + stdout 무출력
# (SessionStart stdout은 컨텍스트에 주입됨). 멱등 — 수동 upgrade와 중복 무해.

CACHE="$HOME/.cache/superct-sync"
STAMP="$CACHE/codex-last-sync"
TTL=$((12 * 3600))

mkdir -p "$CACHE"
now=$(date +%s)
last=$(stat -f %m "$STAMP" 2>/dev/null || stat -c %Y "$STAMP" 2>/dev/null || echo 0)
(( now - last <= TTL )) && exit 0

command -v codex >/dev/null || exit 0
touch "$STAMP"

# marketplace 스냅샷 갱신이 설치된 플러그인 캐시까지 함께 교체한다
# (실측 2026-08-11: upgrade 후 dev 캐시 1.3.0 → 1.4.1)
codex plugin marketplace upgrade > "$CACHE/codex-sync.log" 2>&1 &
disown 2>/dev/null

exit 0
