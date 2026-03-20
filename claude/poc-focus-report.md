# Programmatic Focus POC 결과 보고서

## 1. 확인된 사항

### 성능 벤치마크

| 대상 | 방식 | 레이턴시 |
|------|------|---------|
| WezTerm 탭 전환 | `wezterm cli activate-tab --tab-id` | ~15ms |
| WezTerm 탭 전환 | `--tab-index` / `--tab-relative` | ~16ms |
| Zellij 탭 전환 | `zellij action go-to-tab` | ~19ms |
| Zellij 탭 전환 | `zellij action go-to-tab-name` | ~20ms |
| Zellij pane 이동 | `zellij action move-focus` | ~19ms |
| Zellij pane 포커스 (플러그인) | `focus_terminal_pane(id)` via pipe | ~15ms (추정) |

### 핵심 발견

1. **WezTerm 탭 전환**: `wezterm cli activate-tab --tab-id <id>`가 가장 안정적.
   `--tab-index`/`--tab-relative`는 `--pane-id`를 명시해야 동작 (`$WEZTERM_PANE`이 stale할 수 있음).

2. **Zellij CLI의 한계**: pane ID로 직접 포커스하는 CLI 명령이 없음.
   `move-focus up/down/left/right`로 상대 이동만 가능.

3. **Zellij 플러그인 API로 해결**: `focus_terminal_pane(pane_id, should_float_if_hidden)` API가
   pane ID로 직접 포커스를 지원. **탭 자동 전환 포함** — 다른 탭에 있는 pane이라도 해당 탭으로 전환 후 포커스.

4. **크로스 세션 제어**: `zellij -s <session_name> pipe ...`로 다른 Zellij 세션의 플러그인에
   메시지 전달 가능. 즉 현재 세션에서 다른 세션의 pane을 포커스할 수 있음.

5. **WezTerm + Zellij 조합**: WezTerm 탭 전환 → Zellij pane 포커스 순서로 호출하면
   어떤 WezTerm 탭의 어떤 Zellij 세션의 어떤 pane이든 도달 가능.

### 제약 사항

| 제약 | 설명 | 완화 방법 |
|------|------|----------|
| 플러그인 사전 로드 | 각 Zellij 세션마다 플러그인 로드 + 권한 승인 필요 | `load_plugins`로 config에 등록 |
| pane ID 필요 | 이름이 아닌 ID로만 포커스 가능 | 알림 hook에서 `$ZELLIJ_PANE_ID` 사용 |
| WezTerm 소켓 stale | 재시작 후 `$WEZTERM_UNIX_SOCKET` 갱신 안 됨 | symlink 자동 감지 로직 |
| 권한 승인 UI | 플러그인 최초 로드 시 빈 박스로 보이는 경우 있음 | 원인 추가 조사 필요 |

---

## 2. zellij-focus 플러그인

### 개요

Zellij의 `focus_terminal_pane` plugin API를 CLI pipe로 노출하는 최소 플러그인.
pane ID를 받아 해당 pane으로 포커스를 이동한다. 탭이 다르면 자동으로 탭 전환까지 수행.

### 소스 코드

**`zellij/plugins/zellij-focus/Cargo.toml`**

```toml
[package]
name = "zellij-focus"
version = "0.1.0"
edition = "2021"

[dependencies]
zellij-tile = "0.43.1"

[profile.release]
opt-level = "s"
lto = true
```

**`zellij/plugins/zellij-focus/src/main.rs`**

```rust
use std::collections::BTreeMap;
use zellij_tile::prelude::*;

#[derive(Default)]
struct State {
    pane_manifest: PaneManifest,
}

register_plugin!(State);

impl ZellijPlugin for State {
    fn load(&mut self, _configuration: BTreeMap<String, String>) {
        request_permission(&[
            PermissionType::ChangeApplicationState,
            PermissionType::ReadApplicationState,
        ]);
        subscribe(&[EventType::PaneUpdate]);
    }

    fn pipe(&mut self, pipe_message: PipeMessage) -> bool {
        match pipe_message.name.as_str() {
            // pane ID로 포커스 이동 (탭 자동 전환 포함)
            "focus" => {
                if let Some(payload) = &pipe_message.payload {
                    if let Ok(pane_id) = payload.trim().parse::<u32>() {
                        focus_terminal_pane(pane_id, false);
                    }
                }
            }
            // 전체 pane 목록 반환 (ReadApplicationState 권한 필요)
            "list" => {
                let mut output = String::new();
                for (tab_idx, panes) in &self.pane_manifest.panes {
                    for p in panes {
                        let focus = if p.is_focused { " *" } else { "" };
                        output.push_str(&format!(
                            "tab={} id={} title={:?}{}\n",
                            tab_idx, p.id, p.title, focus
                        ));
                    }
                }
                if let PipeSource::Cli(ref id) = pipe_message.source {
                    cli_pipe_output(id, &output);
                }
            }
            _ => {}
        }
        if let PipeSource::Cli(id) = &pipe_message.source {
            unblock_cli_pipe_input(id);
        }
        false
    }

    fn update(&mut self, event: Event) -> bool {
        if let Event::PaneUpdate(manifest) = event {
            self.pane_manifest = manifest;
        }
        false
    }

    fn render(&mut self, _rows: usize, _cols: usize) {}
}
```

### 빌드

```bash
cd zellij/plugins/zellij-focus
cargo build --release --target wasm32-wasip1
# 출력: target/wasm32-wasip1/release/zellij-focus.wasm (약 820KB)
```

### 사용법

```bash
PLUGIN="file:$HOME/dotfiles/zellij/plugins/zellij-focus/target/wasm32-wasip1/release/zellij-focus.wasm"

# 현재 세션에서 pane 포커스
zellij pipe --plugin "$PLUGIN" --name focus -- "<pane_id>"

# 다른 세션의 pane 포커스
zellij -s <session_name> pipe --plugin "$PLUGIN" --name focus -- "<pane_id>"

# pane 목록 조회 (ReadApplicationState 권한 필요)
zellij pipe --plugin "$PLUGIN" --name list
```

### 요구 권한

| 권한 | 용도 |
|------|------|
| `ChangeApplicationState` | `focus_terminal_pane` 호출에 필요 |
| `ReadApplicationState` | `PaneUpdate` 이벤트 수신 (`list` 기능)에 필요 |

---

## 3. 포커싱 스크립트

### WezTerm 탭 전환

```bash
# 소켓 자동 감지
detect_wezterm_socket() {
  local symlink="$HOME/.local/share/wezterm/default-org.wezfurlong.wezterm"
  if [[ -S "$symlink" ]]; then
    echo "$symlink"
    return
  fi
  ls -t "$HOME"/.local/share/wezterm/gui-sock-* 2>/dev/null | head -1
}

export WEZTERM_UNIX_SOCKET=$(detect_wezterm_socket)

# tab ID로 전환
wezterm cli activate-tab --tab-id <tab_id>

# tab 목록 조회 (JSON)
wezterm cli list --format json
```

### 전체 포커싱 플로우 (WezTerm 탭 + Zellij pane)

```bash
#!/usr/bin/env bash
# focus-pane.sh <wezterm_tab_id> <zellij_session> <zellij_pane_id>

WEZTERM_TAB="$1"
ZELLIJ_SESSION="$2"
PANE_ID="$3"

PLUGIN="file:$HOME/dotfiles/zellij/plugins/zellij-focus/target/wasm32-wasip1/release/zellij-focus.wasm"

# WezTerm 소켓 감지
SYMLINK="$HOME/.local/share/wezterm/default-org.wezfurlong.wezterm"
if [[ -S "$SYMLINK" ]]; then
  export WEZTERM_UNIX_SOCKET="$SYMLINK"
else
  export WEZTERM_UNIX_SOCKET=$(ls -t "$HOME"/.local/share/wezterm/gui-sock-* 2>/dev/null | head -1)
fi

# 1. WezTerm 탭 전환
wezterm cli activate-tab --tab-id "$WEZTERM_TAB"

# 2. Zellij pane 포커스 (탭 자동 전환 포함)
zellij -s "$ZELLIJ_SESSION" pipe --plugin "$PLUGIN" --name focus -- "$PANE_ID"
```

### 알림 hook 통합 예시

기존 Notification hook에서 pane 포커스를 추가하는 경우:

```bash
# claude/hooks/notification-focus.sh
#!/usr/bin/env bash
# $ZELLIJ_PANE_ID — 알림을 발생시킨 Claude 세션의 pane ID
# $ZELLIJ_SESSION_NAME — 해당 세션이 속한 Zellij 세션 이름

PLUGIN="file:$HOME/dotfiles/zellij/plugins/zellij-focus/target/wasm32-wasip1/release/zellij-focus.wasm"

if [[ -n "$ZELLIJ" && -n "$ZELLIJ_PANE_ID" ]]; then
  zellij pipe --plugin "$PLUGIN" --name focus -- "$ZELLIJ_PANE_ID"
fi
```

---

## 4. 파일 구조

```
dotfiles/
├── claude/
│   ├── poc-focus.sh              # 벤치마크 POC 스크립트
│   └── poc-focus-report.md       # 이 보고서
└── zellij/
    ├── config.kdl
    └── plugins/
        └── zellij-focus/
            ├── Cargo.toml
            ├── src/
            │   └── main.rs
            └── target/wasm32-wasip1/release/
                └── zellij-focus.wasm
```
