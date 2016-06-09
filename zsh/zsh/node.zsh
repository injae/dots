export NVM_DIR="$HOME/.nvm"

if [[ -d "$NVM_DIR" && -s "$NVM_DIR/nvm.sh" ]]; then
    source "$NVM_DIR/nvm.sh"
fi

if (( $+commands[npm] )); then
  eval "$(npm completion 2>/dev/null)"

  alias n="npm"
  alias nis="npm --save install"
  alias nus="npm --save uninstall"
  alias nisd="npm --save-dev install"
  alias nusd="npm --save-dev uninstall"
  alias nex='PATH=$(npm bin):$PATH'
fi
