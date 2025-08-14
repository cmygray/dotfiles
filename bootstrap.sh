#!/bin/sh

brew update
brew tap homebrew/bundle
brew bundle --file=$HOME/dotfiles/Brewfile
brew cleanup
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

ln -nfs $HOME/dotfiles/Brewfile $HOME/Brewfile

ln -nfs $HOME/dotfiles/starship.toml $HOME/.config/starship.toml

ln -nfs $HOME/dotfiles/.gitconfig $HOME/.gitconfig
ln -nfs $HOME/dotfiles/.gitignore $HOME/.gitignore

ln -nfs $HOME/dotfiles/gh-dash $HOME/.config/gh-dash

ln -nfs $HOME/dotfiles/.hammerspoon $HOME/.hammerspoon

ln -nfs $HOME/dotfiles/.wezterm.lua $HOME/.wezterm.lua

ln -nfs $HOME/dotfiles/zed/keymap.json $HOME/.config/zed/keymap.json
ln -nfs $HOME/dotfiles/zed/settings.json $HOME/.config/zed/settings.json

# Nushell configuration symlinks
NUSHELL_CONFIG_DIR=$(nu -c '$nu.default-config-dir')
mkdir -p "$NUSHELL_CONFIG_DIR"
ln -nfs $HOME/dotfiles/nushell/config.nu "$NUSHELL_CONFIG_DIR/config.nu"
ln -nfs $HOME/dotfiles/nushell/env.nu "$NUSHELL_CONFIG_DIR/env.nu"

sudo sh -c "echo $(which nu) >> /etc/shells"
chsh -s $(which nu)
