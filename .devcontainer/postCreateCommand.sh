#!/usr/bin/env bash
set -e
set -o noglob

## install task if not available
[ -n "$(command -v chezmoi)" ] || chezmoi init --apply https://github.com/$GITHUB_USERNAME/dotfiles.git

task workstation:krew
