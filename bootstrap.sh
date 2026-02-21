#!/bin/sh

DOTFILES="$HOME/dotfiles"

# Helper: create symlink unconditionally (force-replaces files and broken symlinks)
link() {
    src="$DOTFILES/$1"
    dst="$2"
    mkdir -p "$(dirname "$dst")"
    ln -nfs "$src" "$dst"
    echo "  $dst -> $src"
}

# Install packages
if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found, please install it first"
    exit 1
fi

brew update
brew bundle --file="$DOTFILES/Brewfile"
brew cleanup

# Symlinks
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

echo "Linking Claude Code settings..."
mkdir -p "$HOME/.claude"
link claude/settings.json  "$HOME/.claude/settings.json"
link claude/CLAUDE.md      "$HOME/.claude/CLAUDE.md"
link claude/agents         "$HOME/.claude/agents"
link claude/commands       "$HOME/.claude/commands"
link claude/skills         "$HOME/.claude/skills"

# Install pipx packages
if command -v pipx >/dev/null 2>&1; then
    while read package; do
        [ -n "$package" ] && pipx install "$package"
    done < "$DOTFILES/requirements-pipx.txt"
fi
