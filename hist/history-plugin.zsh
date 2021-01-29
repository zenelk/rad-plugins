export IGNORE_REGEX="${IGNORE_REGEX}|^hist"

# Hook for tying into ZSH process for history adding
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

function hist() {
  local verb
  verb="$1"
  shift

  case "$verb" in
    clear)
      _histClear
      ;;
    del)
      _histDel "$@"
      ;;
    *)
      echo "Unknown verb: '$verb'"
      return 1
  esac
}

function _histClear() {
  rm "$HISTFILE"
  $SHELL -l
}

function _histDel() {
  local resolved_index
  resolved_index="$1"

  if [ "$resolved_index" = "last" ]; then
    resolved_index="$(_histLastIndex)"
  else
    echo "Deleting with context other than 'last' is temporarily removed until I fix the bug"
    return 1
  fi

  while 
    [ -z "$resolved_index" ] || 
    [ -n "${resolved_index//[0-9]/}" ]
  do
    history
    if [ -n "$resolved_index" ]; then
      echo "Index is invalid, please re-enter."
      unset resolved_index
    fi
    printf "Enter index to delete: "
    read -r resolved_index
  done

  local command_to_delete
  command_to_delete="$(_histCommandAtIndex "$resolved_index")"

  _histPurgeCommand "$command_to_delete"
}

function _histLastIndex() {
  [[ "$(history | tail -n 1)" =~ '^[[:space:]]+([[:digit:]]+)' ]] && echo "${match[1]}"
}

function _histCommandAtIndex() {
  while read -r line; do
    if [[ "$line" =~ "^[[:space:]]+$1[[:space:]]+(.*)$" ]]; then
      echo "${match[1]}"
      break
    fi
  done < <(history)
}

function _histPurgeCommand() {
  local sed_deletions
  sed_deletions=""
  local current_line
  current_line=1

  while read -r line; do
    if [[ "$line" =~ "^: [[:digit:]]+:[[:digit:]]+;$1$" ]]; then
      sed_deletions+="${current_line}d;"
    fi

    ((++current_line))
  done < "$HISTFILE"

  sed -i '' "$sed_deletions" "$HISTFILE"
}
