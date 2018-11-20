typeset -U path

export GOPATH=${HOME}/code/go

export NODE_PATH=/usr/local/lib/node_modules:$NODE_PATH

if command_exists rustc; then
  # rustup component add rust-src
  export RUST_SRC_PATH=$(rustc --print sysroot)/lib/rustlib/src/rust/src

  # rust libraries
  export LD_LIBRARY_PATH=$(rustc --print sysroot)/lib:$LD_LIBRARY_PATH
fi

mkdir -p ~/bin

path=(
  ~/bin
  "$path[@]"

  ~/.cargo/bin
  ~/.rbenv/bin
  ~/.cabal/bin
  ~/.rvm/bin

  /usr/local/texlive/2018/bin/x86_64-linux
  ${GOPATH}/bin
  /Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin
)

# prune paths that don't exist
path=($^path(N))

hash_override
