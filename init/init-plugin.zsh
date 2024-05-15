# Allows for functions to be reloaded when used like so:
# function_redefine foo
# function foo() { ... }
function function_redefine() {
  while (( $# )); do
    if function_exists "$1"; then
      unfunction "$1"
    fi
    autoload -U "$1"
    shift
  done
}

function function_exists() {
  declare -f "$1" > /dev/null
}

# Hook for tying into ZSH process for history adding
function_redefine zshaddhistory
function zshaddhistory() {
  emulate -L zsh

  # Ignore failed commands
  whence ${${(z)1}[1]} >| /dev/null || return 1

  # Ignore commands that start with a single space
  if [[ "$1" =~ "^ " ]]; then
    return 1
  fi

  print -sr -- "${1%%$'\n'}"
  fc -p
}
