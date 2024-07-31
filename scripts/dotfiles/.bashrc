# general stuff
export EDITOR=vim
export HISTIGNORE="pwd:ls:cd"
export HISTCONTROL=ignoreboth
export HISTFILESIZE=150000
export HISTSIZE=150000
export HISTTIMEFORMAT="%D %I:%M "
export PAGER=less
export LESS='-R -i -g'
export GREP_COLORS='1;37;41'

# Color man pages
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;38;5;74m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[38;5;246m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[04;38;5;146m'

for files in ~/{.aliases,.functions,.kubectl_aliases,.vimrc}; do
  if [[ -r "$files" ]] && [[ -f "$files" ]]; then
    # shellcheck disable=SC1090
    source "$files"
  fi
done

##source /etc/profile.d/bash_completion.sh

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

set -o vi
alias vi="vim"
alias reload="source ~/.bashrc"
##source /etc/profile.d/bash_completion.sh

source <(kubectl completion bash)
alias k='kubectl'
complete -F __start_kubectl k
export do='--dry-run=client -o yaml'

if [ ! -f $HOME/.kube/config ]; then
  mkdir -p $HOME/.kube && touch $HOME/.kube/config
fi

if ls $HOME/.kube/*.cfg 1> /dev/null 2>&1; then
  export KUBECONFIG_HOME=$HOME/.kube
  export KUBECONFIG_LIST=$( ls $HOME/.kube/*.cfg | xargs -n 1 basename | xargs -I {} echo $KUBECONFIG_HOME/{} )
  export KUBECONFIG=$( echo $KUBECONFIG_LIST | tr ' ' ':' )
  kubectl config view --flatten >| $HOME/.kube/config
  export KUBECONFIG=$HOME/.kube/config
  chmod 600 $HOME/.kube/config
  kubectl config-cleanup --clusters --users --print-removed -o=jsonpath='{ range.contexts[*] }{ .context.cluster }{"\n"}' -t 2 | xargs -I {} rm -f ~/.kube/{}.cfg
fi

set_terminal_title $ENVIRONMENT

export PATH=/usr/local/bin:/usr/local/sbin:$PATH

## add arkade bin
export PATH=$PATH:$HOME/.arkade/bin/

## add krew bin
export PATH=$PATH:$HOME/.krew/bin/

## PS1 prompt to include git and kube-ps1 prompt
source /opt/kube-ps1/kube-ps1.sh
export KUBE_PS1_SYMBOL_ENABLE=false
KUBE_PS1_SYMBOL_ENABLE=true
KUBE_PS1_SYMBOL_PADDING=true
KUBE_PS1_PREFIX=[
KUBE_PS1_SUFFIX=]

export PS1="\n\[\033[32m\]\W\[\033[33m\]\$(parse_git_branch)\[\033[00m\] \$(kube_ps1)\[\033[00m\] \n$ "

########
## Below added by scripts

