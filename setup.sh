#!/bin/bash

# setup.sh
# Creates symlinks from dotfiles dir to proper config locations.
# 
# Michael Gilchrist <michaelgilch@gmail.com>

DOTFILES_DIR=$(pwd)
CONFIG_DIR="$HOME"/.config

create_symlink()
{
    [[ -e $2 ]] && rm "$2"
    ln -s "$1" "$2"
}

# create configuration directory if it does not yet exist
[[ -d "$CONFIG_DIR" ]] || mkdir "$CONFIG_DIR"

# bash
[[ $(pacman -Q bash 2>/dev/null) != "" ]] && {
    create_symlink "$DOTFILES_DIR"/bash/bashrc          "$HOME"/.bashrc
    create_symlink "$DOTFILES_DIR"/bash/bash_profile    "$HOME"/.bash_profile
    create_symlink "$DOTFILES_DIR"/bash/bash_logout     "$HOME"/.bash_logout
    create_symlink "$DOTFILES_DIR"/bash/bash_aliases    "$HOME"/.bash_aliases
    create_symlink "$DOTFILES_DIR"/bash/bash_functions  "$HOME"/.bash_functions
    create_symlink "$DOTFILES_DIR"/bash/bash_prompts    "$HOME"/.bash_prompts
    create_symlink "$DOTFILES_DIR"/bash/less_termcap    "$HOME"/.less_termcap
}

# git 
[[ $(pacman -Q git 2>/dev/null) != "" ]] && \
    create_symlink "$DOTFILES_DIR"/git/gitconfig        "$HOME"/.gitconfig

# nitrogen
[[ $(pacman -Q nitrogen 2>/dev/null) != "" ]] && \
    create_symlink "$DOTFILES_DIR"/nitrogen             "$CONFIG_DIR"/nitrogen

# openbox
[[ $(pacman -Q openbox 2>/dev/null) != "" ]] && \
    create_symlink "$DOTFILES_DIR"/openbox              "$CONFIG_DIR"/openbox

# readline
[[ $(pacman -Q readline 2>/dev/null) != "" ]] && \
    create_symlink "$DOTFILES_DIR"/readline/inputrc     "$HOME"/.inputrc

[[ $(pacman -Q sqlite3 2>/dev/null) != "" ]] && \
    create_symlink "$DOTFILES_DIR"/sqlite3/sqliterc 	"$HOME"/.sqliterc

# sublime-text-3
[[ $(pacman -Q sublime-text 2>/dev/null) != "" ]] && \
    rm -rf "$CONFIG_DIR"/sublime-text-3/Packages/User 
    create_symlink "$DOTFILES_DIR"/sublime              "$CONFIG_DIR"/sublime-text-3/Packages/User

# terminator
[[ $(pacman -Q terminator 2>/dev/null) != "" ]] && \
    create_symlink "$DOTFILES_DIR"/terminator           "$CONFIG_DIR"/terminator

# tint2
[[ $(pacman -Q tint2 2>/dev/null) != "" ]] && \
    create_symlink "$DOTFILES_DIR"/tint2                "$CONFIG_DIR"/tint2

# vim
[[ $(pacman -Q vim 2>/dev/null) != "" ]] && \
    create_symlink "$DOTFILES_DIR"/vim                  "$HOME"/.vim

# volumeicon
[[ $(pacman -Q volumeicon 2>/dev/null) != "" ]] && \
    create_symlink "$DOTFILES_DIR"/volumeicon           "$CONFIG_DIR"/volumeicon

# xdg
[[ $(pacman -Q xdg-user-dirs 2>/dev/null) != "" ]] && \
    create_symlink "$DOTFILES_DIR"/xdg/user-dirs.dirs   "$CONFIG_DIR"/user-dirs.dirs
