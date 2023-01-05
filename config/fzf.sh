#!/bin/bash

this_dir="$(dirname $(readlink -f ${BASH_SOURCE[0]}))"
root_dir="${this_dir}/.."

[ ! -f "${this_dir}/fzf/fzf.bash" ] && echo "fzf is not installed. Please run install.sh script first" && return

source "${this_dir}/fzf/fzf.bash"
source "${root_dir}/fzf-git.sh/fzf-git.sh"

export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {}'"
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
export FZF_ALT_C_OPTS="--prompt 'Directories> ' --header 'Jump into...'"
#export FZF_ALT_C_COMMAND="cd $(find . -type d -print | fzf)"

# FZF custom functions
# -------------------

# Find file or directory
ffind() {
  local dir
  dir=$(find ${1:-*} | fzf ${FZF_DEFAULT_OPTS} \
                           --prompt 'ALL> ' \
                           --header 'CTRL-D: Directories / CTRL-F: Files' \
                           --bind 'ctrl-d:change-prompt(Directories> )+reload(find * -type d)' \
                           --bind 'ctrl-f:change-prompt(Files> )+reload(find * -type f)' \
                           +m) &&
  cd "$dir"
}

# Execute user defined function
ffunc() {
  local func
  func=$(compgen -a -A function | grep -v '^_' | fzf) && eval "${func}"
}

# Search for entry and open selected file in an editor
fopen() {
  IFS=: read -ra selected < <( \
    FZF_DEFAULT_COMMAND="$RG_PREFIX $(printf %q "$INITIAL_QUERY")" \
    FZF_DEFAULT_OPTS="" \
    fzf --ansi \
        --color "hl:-1:underline,hl+:-1:underline:reverse" \
        --disabled --query "$INITIAL_QUERY" \
        --bind "change:reload:sleep 0.1; $RG_PREFIX {q} || true" \
        --bind "ctrl-f:unbind(change,ctrl-f)+change-prompt(2. fzf> )+enable-search+clear-query+rebind(ctrl-r)" \
        --bind "ctrl-r:unbind(ctrl-r)+change-prompt(1. ripgrep> )+disable-search+reload($RG_PREFIX {q} || true)+rebind(change,ctrl-f)" \
        --prompt '1. Ripgrep> ' \
        --delimiter : \
        --header '╱ CTRL-R (Ripgrep mode) ╱ CTRL-F (fzf mode) ╱' \
        --preview 'bat --color=always {1} --highlight-line {2}' \
        --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
  ) \
  [ -n "${selected[0]}" ] && vim "${selected[0]}" "+${selected[1]}"
}
