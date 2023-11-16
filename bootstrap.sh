#!/bin/sh

brew update
brew tap homebrew/bundle
brew bundle --file=$HOME/dotfiles/Brewfile
brew cleanup
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

[ ! -f $HOME/Brewfile ] && ln -nfs $HOME/dotfiles/Brewfile $HOME/Brewfile

[ ! -f $HOME/.config/starship.toml ] && ln -nfs $HOME/dotfiles/starship.toml $HOME/.config/starship.toml

[ ! -f $HOME/.gitconfig ] && ln -nfs $HOME/dotfiles/.gitconfig $HOME/.gitconfig
[ ! -f $HOME/.gitignore ] && ln -nfs $HOME/dotfiles/.gitignore $HOME/.gitignore

rm -rf $HOME/.hammerspoon && ln -nfs $HOME/dotfiles/.hammerspoon $HOME/.hammerspoon

