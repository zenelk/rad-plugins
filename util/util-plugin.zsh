export IGNORE_REGEX="^ |^gc -m"

alias myip="ifconfig en0 | grep inet | grep -v inet6 | awk '{printf \"%s\", \$2}'"

function cdup {
	if ! [[ $1 =~ '^[0-9]+$' && $1 > 0 ]]; then
		echo "Entered value is invalid: $1"
		return 1
	fi
	for i in $(seq 1 $1); do
		cd ..
	done
}

function zshaddhistory() {
  emulate -L zsh

  # Ignore failed commands
  whence ${${(z)1}[1]} >| /dev/null || return 1 

  # Ignore commands that match regex
  if ! [[ "$1" =~ ($IGNORE_REGEX) ]]; then
      print -sr -- "${1%%$'\n'}"
      fc -p
  else
      return 1
  fi
}
