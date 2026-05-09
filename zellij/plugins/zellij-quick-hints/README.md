# zellij-quick-hints

PoC for a WezTerm Quick Select / tmux-thumbs style workflow in Zellij.

This version targets Zellij 0.44.1. It does not use a floating pane or a dumped
screen file. Instead it runs as a background plugin and uses Zellij's regex
highlight API directly on the currently focused terminal pane.

Current UX:

1. Press `Alt y`.
2. Matching text in the focused pane is highlighted for 20 seconds.
3. Alt-click a highlighted match to copy it to the clipboard.
4. Press `Alt y` again to clear the current highlights.

This is not yet the final keyboard-label UX. Zellij 0.44.1 can highlight regex
matches and report highlight clicks, but it does not expose an API for drawing
arbitrary label text over specific coordinates in another pane.

## Build

Use the rustup toolchain, not Homebrew Rust:

```sh
cd ~/dotfiles/zellij/plugins/zellij-quick-hints
PATH="$HOME/.cargo/bin:$PATH" cargo build --release --target wasm32-wasip1
```

Output:

```text
target/wasm32-wasip1/release/zellij-quick-hints.wasm
```

## Zellij Config

The plugin is loaded in the background:

```kdl
load_plugins {
    "file:/Users/classting-won/dotfiles/zellij/plugins/zellij-quick-hints/target/wasm32-wasip1/release/zellij-quick-hints.wasm"
}
```

The activation keybinding sends an `activate` pipe message to the background
plugin:

```kdl
bind "Alt y" {
    MessagePlugin "file:/Users/classting-won/dotfiles/zellij/plugins/zellij-quick-hints/target/wasm32-wasip1/release/zellij-quick-hints.wasm" {
        name "activate"
        skip_cache true
    }
    SwitchToMode "normal"
}
```

## Pattern Set

The matcher includes WezTerm's default Quick Select patterns from
`20240203-110809-5046fc22`, plus the three custom patterns from
`~/.wezterm.lua`:

- 27-character alphanumeric IDs
- 21-character alphanumeric IDs
- email addresses
