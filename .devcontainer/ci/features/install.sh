#!/usr/bin/env bash
set -e
set -o noglob

## install task if not available
[ -n "$(command -v task)" ] || sudo sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b /usr/local/bin

task workstation:arkade

# apk add --no-cache \
#     bash bind-tools ca-certificates curl python3 \
#         py3-pip moreutils jq git iputils \
#             openssh-client starship fzf

# apk add --no-cache \
#     --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community \
#         age direnv helm kubectl kustomize sops

# sudo apk add --no-cache \
#     --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing \
#         lsd

# for installer_path in \
#     "cli/cli!!?as=gh" \
#     "derailed/k9s!" \
#     "fluxcd/flux2!!?as=flux" \
#     "go-task/task!" \
#     "kubecolor/kubecolor!" \
#     "stern/stern!" \
#     "yannh/kubeconform!" \
#     "mikefarah/yq!"
# do
#     curl -fsSL "https://i.jpillora.com/${installer_path}" | bash
# done

# # Create the bash configuration directory
# mkdir -p ${HOME}/.config/bash/{completions,conf.d}

# # Setup autocompletions for bash
# for tool in flux helm k9s kubectl kustomize; do
#     $tool completion bash > ${HOME}/.config/bash/completions/$tool.bash
# done
# gh completion --shell bash > ${HOME}/.config/bash/completions/gh.bash
# stern --completion bash > ${HOME}/.config/bash/completions/stern.bash
# yq shell-completion bash > ${HOME}/.config/bash/completions/yq.bash

# # Add hooks into bash
# tee ${HOME}/.config/bash/conf.d/hooks.bash > /dev/null <<EOF
# if status is-interactive
#     starship init bash | source
# end
# EOF

# # Add aliases into bash
# tee ${HOME}/.config/bash/conf.d/aliases.bash > /dev/null <<EOF
# alias ls lsd
# alias kubectl kubecolor
# alias k kubectl
# EOF

# # # Custom bash prompt
# # tee ${HOME}/.config/bash/conf.d/bash_greeting.bash > /dev/null <<EOF
# # function bash_greeting
# #     echo (set_color yellow)"Welcome! Press [enter] if you see a direnv error"
# # end
# # EOF

# # Set ownership of bash directory to the coder user
# chown -R coder:coder ${HOME}/.config/bash
