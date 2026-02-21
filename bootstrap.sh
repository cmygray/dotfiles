#!/bin/sh

# Install packages only if not already installed
if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found, please install it first"
    exit 1
fi

brew update
brew bundle --file=$HOME/dotfiles/Brewfile
brew cleanup

# Ensure .config directory exists
mkdir -p "$HOME/.config"
[ ! -L "$HOME/.config/starship.toml" ] && ln -nfs $HOME/dotfiles/starship.toml $HOME/.config/starship.toml
[ ! -L "$HOME/.config/nvim" ] && ln -nfs $HOME/dotfiles/nvim $HOME/.config/nvim

[ ! -L "$HOME/.gitconfig" ] && ln -nfs $HOME/dotfiles/.gitconfig $HOME/.gitconfig
[ ! -L "$HOME/.gitignore" ] && ln -nfs $HOME/dotfiles/.gitignore $HOME/.gitignore

[ ! -L "$HOME/.config/gh-dash" ] && ln -nfs $HOME/dotfiles/gh-dash $HOME/.config/gh-dash

[ ! -L "$HOME/.hammerspoon" ] && ln -nfs $HOME/dotfiles/.hammerspoon $HOME/.hammerspoon

[ ! -L "$HOME/.wezterm.lua" ] && ln -nfs $HOME/dotfiles/.wezterm.lua $HOME/.wezterm.lua

mkdir -p "$HOME/.config/zed"
[ ! -L "$HOME/.config/zed/keymap.json" ] && ln -nfs $HOME/dotfiles/zed/keymap.json $HOME/.config/zed/keymap.json
[ ! -L "$HOME/.config/zed/settings.json" ] && ln -nfs $HOME/dotfiles/zed/settings.json $HOME/.config/zed/settings.json

mkdir -p "$HOME/.config/karabiner"
[ ! -L "$HOME/.config/karabiner/karabiner.json" ] && ln -nfs $HOME/dotfiles/karabiner/karabiner.json $HOME/.config/karabiner/karabiner.json

# zsh configuration symlinks
[ ! -L "$HOME/.zshrc" ] && ln -nfs $HOME/dotfiles/.zshrc $HOME/.zshrc
[ ! -L "$HOME/.zshenv" ] && ln -nfs $HOME/dotfiles/.zshenv $HOME/.zshenv

# Install pipx packages
if command -v pipx >/dev/null 2>&1; then
    while read package; do
        [ -n "$package" ] && pipx install "$package"
    done < $HOME/dotfiles/requirements-pipx.txt
fi

# Claude Code global settings (symlink settings.global.json, not settings.json)
mkdir -p "$HOME/.claude"
[ ! -L "$HOME/.claude/settings.json" ] && ln -nfs $HOME/dotfiles/.claude/settings.global.json "$HOME/.claude/settings.json"
