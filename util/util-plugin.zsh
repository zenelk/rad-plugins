alias myip="ifconfig en0 | grep inet | grep -v inet6 | awk '{printf \"%s\", \$2}'"
alias ls='ls -al'

function_redefine cdup
function cdup() {
  if ! [[ $1 =~ '^[0-9]+$' && $1 > 0 ]]; then
    echo "Entered value is invalid: $1"
    return 1
  fi
  for i in $(seq 1 $1); do
    cd ..
  done
}

# Hook for tying into ZSH process for history adding
function_redefine zshaddhistory
function zshaddhistory() {
  emulate -L zsh

  # Ignore failed commands
  whence ${${(z)1}[1]} >| /dev/null || return 1

  # Only remember commands that precede with a single space
  if [[ ! "$1" =~ "^ " ]]; then
    return 1
  fi

  print -sr -- "${1%%$'\n'}"
  fc -p
}
