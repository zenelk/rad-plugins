export _ZK_HIST_IGNORES=()

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

  # Ignore commands that are added to the ignores list
  local no_newline="${1%%$'\n'}"
  local command="${no_newline% *}"
  if _hist_is_command_ignored "$command"; then
    return 1
  else
    print -sr -- "$no_newline"
    fc -p
  fi
}

function_redefine _hist_is_command_ignored
function _hist_is_command_ignored() {
  (($_ZK_HIST_IGNORES[(Ie)$1]))
}

function_redefine hist
function hist() {
  local verb
  verb="$1"
  shift

  case "$verb" in
    --clear)
      _histClear
      ;;
    --del)
      _histDel "$@"
      ;;
    --add-ignore)
      _histAddIgnore "$@"
      ;;
    *)
      echo "Unknown verb: '$verb'"
      return 1
  esac
}

function_redefine _histClear
function _histClear() {
  echo "" >| "$HISTFILE"
  $SHELL -l
}

function_redefine _histDel
function _histDel() {
  local resolved_index="$1"

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

function_redefine _histAddIgnore
function _histAddIgnore() {
  _ZK_HIST_IGNORES+=("$1")
}

function_redefine _histLastIndex
function _histLastIndex() {
  [[ "$(history | tail -n 1)" =~ '^[[:space:]]+([[:digit:]]+)' ]] && echo "${match[1]}"
}

function_redefine _histCommandAtIndex
function _histCommandAtIndex() {
  while read -r line; do
    if [[ "$line" =~ "^[[:space:]]+$1[[:space:]]+(.*)$" ]]; then
      echo "${match[1]}"
      break
    fi
  done < <(history)
}

function_redefine _histPurgeCommand
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
