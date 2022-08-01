#!/bin/sh

brew update
brew tap homebrew/bundle
brew bundle --file=$HOME/dotfiles/Brewfile
brew cleanup
brew cask cleanup

sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

[ ! -f $HOME/Brewfile ] && ln -nfs $HOME/dotfiles/Brewfile $HOME/Brewfile

[ ! -f $HOME/.zshrc ] && ln -nfs $HOME/dotfiles/.zshrc $HOME/.zshrc
[ ! -f $HOME/.zshenv ] && ln -nfs $HOME/dotfiles/.zshenv $HOME/.zshenv
[ ! -f $HOME/.zprofile ] && ln -nfs $HOME/dotfiles/.zprofile $HOME/.zprofile
source $HOME/.zshrc

[ ! -f $HOME/.config/starship.toml ] && ln -nfs $HOME/dotfiles/starship.toml $HOME/.config/starship.toml

[ ! -f $HOME/.gitconfig ] && ln -nfs $HOME/dotfiles/.gitconfig $HOME/.gitconfig
[ ! -f $HOME/.gitignore ] && ln -nfs $HOME/dotfiles/.gitignore $HOME/.gitignore

[ ! -f $HOME/.vim ] && ln -nfs $HOME/dotfiles/.vim $HOME/.vim

rm -rf $HOME/.oh-my-zsh/custom && ln -nfs $HOME/dotfiles/.oh-my-zsh/custom $HOME/.oh-my-zsh/custom

rm -rf $HOME/.hammerspoon && ln -nfs $HOME/dotfiles/.hammerspoon $HOME/.hammerspoon

