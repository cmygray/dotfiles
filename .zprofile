CPU=$(uname -m)
if [[ "$CPU" == "arm64" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  export PATH=/opt/homebrew/bin:$PATH
  eval "$(/usr/local/bin/brew shellenv)"
  export ASDF_DATA_DIR=$HOME/.asdf-x86
fi

iterm2_print_user_vars() {
  CPU=$(uname -m)
  iterm2_set_user_var cpu $CPU
}

export RUST_WITHOUT=rust-docs

