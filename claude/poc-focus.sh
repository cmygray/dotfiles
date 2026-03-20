#!/usr/bin/env bash
# POC: Programmatic Focus Control for WezTerm + Zellij
# Usage: ./poc-focus.sh [wezterm|zellij|all]
set -euo pipefail

# ── Auto-detect WezTerm socket ──
detect_wezterm_socket() {
  local symlink="$HOME/.local/share/wezterm/default-org.wezfurlong.wezterm"
  if [[ -S "$symlink" ]]; then
    echo "$symlink"
    return
  fi
  # fallback: find the latest gui-sock
  local sock
  sock=$(ls -t "$HOME"/.local/share/wezterm/gui-sock-* 2>/dev/null | head -1)
  echo "${sock:-}"
}

WEZTERM_SOCK=$(detect_wezterm_socket)

# ── Benchmark helper ──
bench() {
  local label="$1"; shift
  local start end elapsed
  start=$(python3 -c 'import time; print(time.time())')
  "$@" 2>/dev/null
  end=$(python3 -c 'import time; print(time.time())')
  elapsed=$(python3 -c "print(f'{($end - $start) * 1000:.1f}')")
  printf "  %-40s %6s ms\n" "$label" "$elapsed"
}

# ── WezTerm Tests ──
test_wezterm() {
  echo "═══ WezTerm Focus Tests ═══"
  echo ""

  if [[ -z "$WEZTERM_SOCK" ]]; then
    echo "  ERROR: WezTerm socket not found"
    return 1
  fi

  export WEZTERM_UNIX_SOCKET="$WEZTERM_SOCK"

  # List tabs
  echo "  Tabs:"
  wezterm cli list --format json | python3 -c "
import json, sys
for t in json.load(sys.stdin):
    active = '→' if t.get('is_active') else ' '
    print(f\"    {active} tab_id={t['tab_id']}  title=\\\"{t['tab_title']}\\\"  pane_id={t['pane_id']}\")
"
  echo ""

  # Get current tab info (use tab_title match since WEZTERM_PANE may be stale)
  local current_tab_id
  current_tab_id=$(wezterm cli list --format json | python3 -c "
import json, sys
for t in json.load(sys.stdin):
    if t['tab_title'] == 'wez':
        print(t['tab_id']); break
")

  # Find "test" tab
  local test_tab_id
  test_tab_id=$(wezterm cli list --format json | python3 -c "
import json, sys
for t in json.load(sys.stdin):
    if t['tab_title'] == 'test':
        print(t['tab_id']); break
" 2>/dev/null || true)

  if [[ -z "$test_tab_id" ]]; then
    echo "  WARN: 'test' tab not found, skipping tab switch test"
    return
  fi

  # Resolve a live pane_id for --pane-id (WEZTERM_PANE env may be stale)
  local live_pane_id
  live_pane_id=$(wezterm cli list --format json | python3 -c "
import json, sys
for t in json.load(sys.stdin):
    if t['tab_id'] == $current_tab_id:
        print(t['pane_id']); break
")

  echo "  Benchmarks:"

  # Switch to test tab
  bench "activate-tab --tab-id (to test)" \
    wezterm cli activate-tab --tab-id "$test_tab_id"

  # Switch back
  bench "activate-tab --tab-id (back)" \
    wezterm cli activate-tab --tab-id "$current_tab_id"

  # By index (need --pane-id since WEZTERM_PANE is stale)
  bench "activate-tab --tab-index 1" \
    wezterm cli activate-tab --tab-index 1 --pane-id "$live_pane_id"

  bench "activate-tab --tab-index 0 (back)" \
    wezterm cli activate-tab --tab-index 0 --pane-id "$live_pane_id"

  # Relative
  bench "activate-tab --tab-relative 1" \
    wezterm cli activate-tab --tab-relative 1 --pane-id "$live_pane_id"

  bench "activate-tab --tab-relative -1 (back)" \
    wezterm cli activate-tab --tab-relative -1 --pane-id "$live_pane_id"

  echo ""
}

# ── Zellij Tests ──
test_zellij() {
  echo "═══ Zellij Focus Tests ═══"
  echo ""

  if [[ -z "${ZELLIJ:-}" ]]; then
    echo "  ERROR: Not inside a Zellij session"
    return 1
  fi

  echo "  Session: $ZELLIJ_SESSION_NAME  Pane: $ZELLIJ_PANE_ID"
  echo "  Tabs:"
  local i=1
  while IFS= read -r name; do
    printf "    %d. %s\n" "$i" "$name"
    ((i++))
  done < <(zellij action query-tab-names)
  echo ""

  local tab_count=$((i - 1))

  echo "  Benchmarks (tab):"

  # Tab by number
  if ((tab_count >= 2)); then
    bench "go-to-tab 2" \
      zellij action go-to-tab 2

    bench "go-to-tab 1 (back)" \
      zellij action go-to-tab 1
  fi

  # Tab by name
  local first_tab
  first_tab=$(zellij action query-tab-names | head -1)
  local second_tab
  second_tab=$(zellij action query-tab-names | sed -n '2p')

  if [[ -n "$second_tab" ]]; then
    bench "go-to-tab-name \"$second_tab\"" \
      zellij action go-to-tab-name "$second_tab"

    bench "go-to-tab-name \"$first_tab\" (back)" \
      zellij action go-to-tab-name "$first_tab"
  fi

  # Next/previous
  bench "go-to-next-tab" \
    zellij action go-to-next-tab

  bench "go-to-previous-tab (back)" \
    zellij action go-to-previous-tab

  echo ""
  echo "  Benchmarks (pane):"

  # Pane focus
  bench "move-focus down" \
    zellij action move-focus down

  bench "move-focus up (back)" \
    zellij action move-focus up

  bench "move-focus right" \
    zellij action move-focus right

  bench "move-focus left (back)" \
    zellij action move-focus left

  bench "focus-next-pane" \
    zellij action focus-next-pane

  bench "focus-previous-pane (back)" \
    zellij action focus-previous-pane

  echo ""
}

# ── Zellij cross-session test ──
test_zellij_cross_session() {
  echo "═══ Zellij Cross-Session Focus (via WezTerm) ═══"
  echo ""
  echo "  Strategy: WezTerm tab switch → target session's Zellij takes focus"
  echo ""

  if [[ -z "$WEZTERM_SOCK" ]]; then
    echo "  ERROR: WezTerm socket not found"
    return 1
  fi

  export WEZTERM_UNIX_SOCKET="$WEZTERM_SOCK"

  local test_tab_id
  test_tab_id=$(wezterm cli list --format json | python3 -c "
import json, sys
for t in json.load(sys.stdin):
    if t['tab_title'] == 'test':
        print(t['tab_id']); break
" 2>/dev/null || true)

  local current_tab_id
  current_tab_id=$(wezterm cli list --format json | python3 -c "
import json, sys
for t in json.load(sys.stdin):
    if t['tab_title'] == 'wez':
        print(t['tab_id']); break
" 2>/dev/null || true)

  if [[ -z "$test_tab_id" || -z "$current_tab_id" ]]; then
    echo "  WARN: tabs not found, skipping"
    return
  fi

  echo "  Benchmarks:"

  # Combined: switch WezTerm tab + send Zellij action
  bench "wezterm→test + zellij go-to-tab 2" \
    bash -c "
      export WEZTERM_UNIX_SOCKET='$WEZTERM_SOCK'
      wezterm cli activate-tab --tab-id $test_tab_id 2>/dev/null
    "

  bench "wezterm→back" \
    bash -c "
      export WEZTERM_UNIX_SOCKET='$WEZTERM_SOCK'
      wezterm cli activate-tab --tab-id $current_tab_id 2>/dev/null
    "

  echo ""
}

# ── Main ──
mode="${1:-all}"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  Programmatic Focus POC                  ║"
echo "╚══════════════════════════════════════════╝"
echo ""

case "$mode" in
  wezterm) test_wezterm ;;
  zellij)  test_zellij ;;
  all)
    test_wezterm
    test_zellij
    test_zellij_cross_session
    ;;
  *) echo "Usage: $0 [wezterm|zellij|all]" ;;
esac
