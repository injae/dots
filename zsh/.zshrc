# determine path to dots dir

[[ -n "$ENABLE_ZPROF" ]] && zmodload zsh/zprof

if [[ -n "$ENABLE_XTRACE" ]]; then
  zmodload zsh/datetime
  setopt PROMPT_SUBST
  PS4='+$EPOCHREALTIME %N:%i> '

  logfile=$(mktemp zsh_profile.XXXXXXXX)
  echo "Logging to $logfile"
  exec 3>&2 2>$logfile

  setopt XTRACE
fi

if [[ "$OSTYPE" == darwin* ]]; then
  export MACOS=1

  path=(
    /usr/local/opt/coreutils/libexec/gnubin
    /usr/local/opt/findutils/libexec/gnubin
    /usr/local/opt/gnu-tar/libexec/gnubin
    /usr/local/opt/gnu-sed/libexec/gnubin
    /usr/local/opt/gnu-getopt/bin
    /usr/local/opt/grep/libexec/gnubin
    "$path[@]"
  )

  manpath=(
    /usr/local/opt/coreutils/libexec/gnuman
    /usr/local/opt/findutils/libexec/gnuman
    /usr/local/opt/gnu-tar/libexec/gnuman
    /usr/local/opt/gnu-sed/libexec/gnuman
    /usr/local/opt/grep/libexec/gnuman
    "$manpath[@]"
  )
fi

export DOTSPATH="$(cd $(dirname $(dirname $(readlink -f ${(%):-%N}))); pwd)"

# TODO
# Warn when expected programs/packages aren't available.

# When setting up for Emacs Tramp, set the prompt to something simple that it
# can detect and disable superfluous features in order to optimize for speed.
if [[ "$TERM" == "dumb" ]]; then
  unsetopt zle
  unsetopt prompt_cr
  unsetopt prompt_subst

  if whence -w precmd >/dev/null; then
    unfunction precmd
  fi

  if whence -w preexec >/dev/null; then
    unfunction preexec
  fi

  PS1='$ '

  return
fi

# if TMUX_FZF is set, we're only interested in loading the fzf functions
# everything else will just slow us down
if [[ -n "$TMUX_FZF" ]]; then
  source $DOTSPATH/zsh/zsh/fzf.zsh
  return
fi

fpath=(
  "$HOME/.zsh/comp"
  "$DOTSPATH/zsh/zsh/comp"
  "${fpath[@]}"
)

autoload -U compinit bashcompinit promptinit colors select-word-style
select-word-style bash
compinit -i
bashcompinit
promptinit
colors

# history
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=10000
export HISTORY_IGNORE=""
export SAVEHIST=$HISTSIZE

setopt inc_append_history
setopt hist_ignore_space
setopt append_history
setopt hist_ignore_dups
setopt share_history
setopt extendedglob
setopt hist_reduce_blanks
setopt hist_verify
setopt no_complete_aliases
setopt auto_pushd
setopt cdable_vars

# env vars
export EDITOR=vim
export VISUAL=vim

# zplug
export ZPLUG_HOME=$HOME/.zplug

if [[ ! -d $ZPLUG_HOME ]]; then
  git clone https://github.com/zplug/zplug $ZPLUG_HOME
fi

source $ZPLUG_HOME/init.zsh

zplug "zplug/zplug"

zplug "hlissner/zsh-autopair", defer:2
zplug "zsh-users/zsh-syntax-highlighting", defer:3
zplug "zsh-users/zsh-completions"
zplug "kutsan/zsh-system-clipboard"

# NOTE: Don't use on macOS because brew is very slow
zplug "plugins/command-not-found", from:oh-my-zsh, defer:3, if:"[[ $OSTYPE != *darwin* ]]"

zplug "b4b4r07/enhancd", use:init.sh

# Install plugins if there are plugins that have not been installed
if ! zplug check; then
  printf "Install? [y/N]: "
  if read -q; then
    echo; zplug install
  fi
fi

zplug load

command_exists() {
  (( $+commands[$1]))
}

function_exists() {
  (( $+functions[$1]))
}

typeset -aU ldflags
typeset -T LDFLAGS ldflags ' '
export LDFLAGS

typeset -aU cppflags
typeset -T CPPFLAGS cppflags ' '
export CPPFLAGS

typeset -aU pkg_config_path
typeset -T PKG_CONFIG_PATH pkg_config_path
export PKG_CONFIG_PATH

# strict control over source order
sources=(
  'path'
  'hub'
  'vcsinfo'
  'prompt'
  'completions'
  'zle'
  'functions'
  'alias'
  'highlight'
  'fzf'
  'enhancd'
  'linux'
  'macos'
)

for src in $sources; do
  source $DOTSPATH/zsh/zsh/$src.zsh
done

if [[ -f ~/.zsh.local ]]; then
  source ~/.zsh.local
fi

[[ -n "$ENABLE_ZPROF" ]] && zprof

if [[ -n "$ENABLE_XTRACE" ]]; then
  unsetopt XTRACE
  exec 2>&3 3>&-
fi
