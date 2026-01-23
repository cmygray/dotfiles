#!/bin/sh

# Install packages only if not already installed
if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found, please install it first"
    exit 1
fi

brew update
brew tap homebrew/bundle
brew bundle --file=$HOME/dotfiles/Brewfile
brew cleanup

# Install oh-my-zsh only if not already installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Create symlinks only if they don't exist or point to wrong location
[ ! -L "$HOME/Brewfile" ] && ln -nfs $HOME/dotfiles/Brewfile $HOME/Brewfile

# Ensure .config directory exists
mkdir -p "$HOME/.config"
[ ! -L "$HOME/.config/starship.toml" ] && ln -nfs $HOME/dotfiles/starship.toml $HOME/.config/starship.toml

[ ! -L "$HOME/.gitconfig" ] && ln -nfs $HOME/dotfiles/.gitconfig $HOME/.gitconfig
[ ! -L "$HOME/.gitignore" ] && ln -nfs $HOME/dotfiles/.gitignore $HOME/.gitignore

mkdir -p "$HOME/.config"
[ ! -L "$HOME/.config/gh-dash" ] && ln -nfs $HOME/dotfiles/gh-dash $HOME/.config/gh-dash

[ ! -L "$HOME/.hammerspoon" ] && ln -nfs $HOME/dotfiles/.hammerspoon $HOME/.hammerspoon

[ ! -L "$HOME/.wezterm.lua" ] && ln -nfs $HOME/dotfiles/.wezterm.lua $HOME/.wezterm.lua

mkdir -p "$HOME/.config/zed"
[ ! -L "$HOME/.config/zed/keymap.json" ] && ln -nfs $HOME/dotfiles/zed/keymap.json $HOME/.config/zed/keymap.json
[ ! -L "$HOME/.config/zed/settings.json" ] && ln -nfs $HOME/dotfiles/zed/settings.json $HOME/.config/zed/settings.json

mkdir -p "$HOME/.config/karabiner"
[ ! -L "$HOME/.config/karabiner/karabiner.json" ] && ln -nfs $HOME/dotfiles/karabiner/karabiner.json $HOME/.config/karabiner/karabiner.json

# Nushell configuration symlinks
if command -v nu >/dev/null 2>&1; then
    NUSHELL_CONFIG_DIR=$(nu -c '$nu.default-config-dir')
    mkdir -p "$NUSHELL_CONFIG_DIR"
    [ ! -L "$NUSHELL_CONFIG_DIR/config.nu" ] && ln -nfs $HOME/dotfiles/nushell/config.nu "$NUSHELL_CONFIG_DIR/config.nu"
    [ ! -L "$NUSHELL_CONFIG_DIR/env.nu" ] && ln -nfs $HOME/dotfiles/nushell/env.nu "$NUSHELL_CONFIG_DIR/env.nu"

    # Add nushell to shells and set as default only if not already done
    if ! grep -q "$(which nu)" /etc/shells; then
        sudo sh -c "echo $(which nu) >> /etc/shells"
    fi
    
    if [ "$SHELL" != "$(which nu)" ]; then
        chsh -s $(which nu)
    fi
    
    # Initialize nushell/scripts sparse checkout
    echo "Initializing nushell/scripts..."
    nu $HOME/dotfiles/init-nushell-scripts.nu
fi

# Install pipx packages
if command -v pipx >/dev/null 2>&1; then
    while read package; do
        [ -n "$package" ] && pipx install "$package"
    done < $HOME/dotfiles/requirements-pipx.txt
fi

# Claude Code global settings (symlink settings.global.json, not settings.json)
mkdir -p "$HOME/.claude"
[ ! -L "$HOME/.claude/settings.json" ] && ln -nfs $HOME/dotfiles/.claude/settings.global.json "$HOME/.claude/settings.json"
