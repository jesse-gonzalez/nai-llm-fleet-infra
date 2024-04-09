#!/usr/bin/env bash
set -e
set -o noglob

## configure local dot files
[ -n "$(command -v chezmoi)" ] || chezmoi init --apply https://github.com/$GITHUB_USERNAME/dotfiles.git

## install krew packages
task workstation:krew
