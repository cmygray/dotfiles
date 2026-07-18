#!/bin/sh

DOTFILES="$HOME/dotfiles"

# Helper: create symlink (force-replaces files and broken symlinks).
# Guard: if dst is a real directory (not a symlink), `ln -nfs` would nest the
# link inside it instead of replacing it — skip and warn instead.
link() {
    src="$DOTFILES/$1"
    dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [ -d "$dst" ] && [ ! -L "$dst" ]; then
        echo "  SKIP $dst (real dir exists — remove it first to avoid nesting)"
        return
    fi
    ln -nfs "$src" "$dst"
    echo "  $dst -> $src"
}

# Symlinks (run before Homebrew — safe over SSH without Homebrew)
echo "Linking dotfiles..."
link .zshrc             "$HOME/.zshrc"
link .zshenv            "$HOME/.zshenv"
link .gitconfig         "$HOME/.gitconfig"
link .gitignore         "$HOME/.gitignore"
link .wezterm.lua       "$HOME/.wezterm.lua"
link .hammerspoon       "$HOME/.hammerspoon"
link starship.toml      "$HOME/.config/starship.toml"
link nvim               "$HOME/.config/nvim"
link gh-dash            "$HOME/.config/gh-dash"
link zed/keymap.json    "$HOME/.config/zed/keymap.json"
link zed/settings.json  "$HOME/.config/zed/settings.json"
link karabiner/karabiner.json "$HOME/.config/karabiner/karabiner.json"
link zellij/config.kdl       "$HOME/.config/zellij/config.kdl"
link ghostty/config          "$HOME/.config/ghostty/config"
# codex/config.toml intentionally NOT linked: the Codex app rewrites it at
# runtime (hooks.state hashes, marketplace timestamps, app version), so it's
# left as the app-managed real file rather than a dotfiles symlink.
link codex/agents            "$HOME/.codex/agents"
link codex/hooks.json        "$HOME/.codex/hooks.json"
link .codex/skills/ship      "$HOME/.codex/skills/ship"
link scripts/pbcopy          "$HOME/.local/bin/pbcopy"
link scripts/portview        "$HOME/.local/bin/portview"
link portview/config.json    "$HOME/.config/portview/config.json"
link launchagents/local.portview.plist "$HOME/Library/LaunchAgents/local.portview.plist"
link launchagents/local.worktree-cleanup.plist "$HOME/Library/LaunchAgents/local.worktree-cleanup.plist"

echo "Linking Claude Code settings..."
mkdir -p "$HOME/.claude"
link claude/settings.json  "$HOME/.claude/settings.json"
link claude/statusline.sh  "$HOME/.claude/statusline.sh"
link claude/CLAUDE.md      "$HOME/.claude/CLAUDE.md"
link claude/agents         "$HOME/.claude/agents"
link claude/commands       "$HOME/.claude/commands"
link claude/skills         "$HOME/.claude/skills"
link claude/rules          "$HOME/.claude/rules"

# Git filters (dotfiles repo)
echo "Configuring git filters..."
git -C "$DOTFILES" config filter.strip-claude-local.clean "jq 'del(.model, .effortLevel)'"
git -C "$DOTFILES" config filter.strip-claude-local.smudge "cat"

# Install packages
if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found, please install it first"
    exit 1
fi

brew update
brew bundle --file="$DOTFILES/Brewfile"
brew cleanup

# Install pipx packages
if command -v pipx >/dev/null 2>&1; then
    while read package; do
        [ -n "$package" ] && pipx install "$package"
    done < "$DOTFILES/requirements-pipx.txt"
fi

# Install gh extensions
if command -v gh >/dev/null 2>&1; then
    while read ext; do
        [ -n "$ext" ] && gh extension install "$ext" 2>/dev/null || true
    done < "$DOTFILES/gh-extensions.txt"
fi
