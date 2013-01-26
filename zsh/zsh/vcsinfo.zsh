# vcsinfo: thanks to github.com/sunaku/home/
autoload -Uz vcs_info

VCS_PRE="%{$fg[red]%}(%{$reset_color%}"
VCS_SUF="%{$fg[red]%})%{$reset_color%}"

AVCS_PRE="%{$fg[green]%}{%{$reset_color%}"
AVCS_SUF="%{$fg[green]%}}%{$reset_color%}"

COLON="%{$fg[red]%}:%{$reset_color%}"
SPACE=" "
DELIM=$SPACE

VCS_PROMPT="$VCS_PRE%b%u%c$VCS_SUF "
AVCS_PROMPT="$VCS_PROMPT$AVCS_PRE%a$AVCS_SUF "

zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' stagedstr '+'
zstyle ':vcs_info:*' unstagedstr '*'
zstyle ':vcs_info:*' formats $VCS_PROMPT
zstyle ':vcs_info:*' actionformats $AVCS_PROMPT
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git*+set-message:*' hooks git-untracked git-message
precmd() { vcs_info }

### git: Show marker (T) if there are untracked files in repository
# Make sure you have added staged to your 'formats':  %c
function +vi-git-untracked(){
    if [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) == 'true' ]] && \
        git status --porcelain | grep '??' &> /dev/null ; then
        # This will show the marker if there are any untracked files in repo.
        # If instead you want to show the marker only if there are untracked
        # files in $PWD, use:
        #[[ -n $(git ls-files --others --exclude-standard) ]] ; then
        if [[ -n ${hook_com[unstaged]} ]]; then
          hook_com[unstaged]="-$DELIM${hook_com[unstaged]}"
        else
          hook_com[unstaged]="-"
        fi
    fi
}

# proper spacing
function +vi-git-message(){
  if [[ -n ${hook_com[unstaged]} ]]; then
    if [[ -n ${hook_com[staged]} ]]; then
      hook_com[unstaged]=" ${hook_com[unstaged]}$DELIM"
    else
      hook_com[unstaged]=" ${hook_com[unstaged]}"
    fi
  else
    if [[ -n ${hook_com[staged]} ]]; then
      hook_com[staged]=" ${hook_com[staged]}"
    fi
  fi
}
