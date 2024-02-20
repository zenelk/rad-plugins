alias myip="ifconfig en0 | grep inet | grep -v inet6 | awk '{printf \"%s\", \$2}'"
alias ls='ls -al'
alias kx='killall Xcode'
alias bef='bundle exec fastlane'

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

  # Ignore commands that start with a single space
  if [[ "$1" =~ "^ " ]]; then
    return 1
  fi

  print -sr -- "${1%%$'\n'}"
  fc -p
}

function_redefine sr
function sr() {
  local quick_select_none='none'
  local quick_select_root='-'

  function echoerr() {
    echo $@ >&2
  }

  function isRootSet() {
    if ! [ -z "${ZK_CODE_ROOT}" ]; then
      return 0
    fi
    return 1
  }

  function isInteger() {
    if [[ "${1}" =~ '^[0-9]+$' ]]; then
      return 0
    fi
    return 1
  }

  function printUnsupportedArgumentError() {
    echoerr "Unsupported argument '${1}' at position ${2}!"
  }

  function validateArguments() {
    case $# in
      0)
        return 0
        ;;
      1)
        if [ "${1}" != "${quick_select_root}" ] && ! isInteger "${1}"; then
          printUnsupportedArgumentError "${1}" 1
          return 1
        fi
        ;;
      2)
        if ! isInteger "${1}"; then
          printUnsupportedArgumentError "${1}" 1
          return 1
        elif ! isInteger "${2}"; then
          printUnsupportedArgumentError "${2}" 2
          return 1
        fi
        return 0
        ;;
      *)
        echoerr "Invalid number of arguments!"
        # ZTODO: Make a usage function.
        return 1
        ;;
    esac
  }

  function parseQuickSelectArgument() {
    if [ -z "${1}" ]; then
      echo "${quick_select_none}"
    else
      echo "${1}"
    fi
  }

  function statOrgs() {
    local orgs=()

    for fd in "${ZK_CODE_ROOT}"/*; do
      if [ ! -d "${fd}" ]; then
        echoerr "File is not a directory: '${fd}'"
        continue
      fi

      local org="$(basename "${fd}")"
      orgs+=("${org}")
    done

    echo "${orgs[@]}"
  }

  function statRepos() {
    local repos=()
    local org_path="${ZK_CODE_ROOT}/${1}"

    for fd in "${org_path}"/*; do
      if [ ! -d "${fd}" ]; then
        echoerr "File is not a directory: '${fd}'"
        continue
      fi

      local repo="$(basename "${fd}")"
      repos+=("${repo}")
    done

    echo "${repos[@]}"
  }

  function echoFormattedPromptLine() {
    echoerr "  ${1}): ${2}"
  }

  function echoFormattedPromptArray() {
    local array=(${@})
    local count="${#}"
    local i=1
    for element in $array; do
      echoFormattedPromptLine "${i}" "${element}"
      i=$((i+1))
    done
  }

  function readSelectionInputFromArray() {
    local array=(${@})
    local count="${#}"
    local selection=""
    local input=""

    while [ -z "${selection}" ]; do
      printf "Enter selection [1-${count}]: " >&2
      read input
      case "${input}" in
        ''|*[!0-9]*)
          echoerr "Not a number! Try again..."
          ;;
        *)
          if [ "${input}" -lt 1 ] || [ "${input}" -gt "${count}" ]; then
            echoerr "Out of bounds! Try again..."
          else
            selection="${input}"
          fi
          ;;
      esac
    done

    echo "${array["${selection}"]}"
  }

  function produceSelectionIndex() {
    local quick_select_index="${1}"
    local section_header="${2}"
    shift 2
    local array=(${@})
    local count="${#}"

    if [ "${quick_select_index}" = "${quick_select_none}" ]; then
      if [ "${count}" -eq 1 ]; then
        echo "${array[1]}"
        return 0
      fi

      echoerr -e "${section_header}"
      echoFormattedPromptArray "${array[@]}"
      echo "$(readSelectionInputFromArray "${array[@]}")"
    elif [ "${quick_select_index}" -lt 1 ] || [ "${quick_select_index}" -gt "${count}" ]; then
      echoerr "Quick select org index '${quick_select_index}' out of bounds '[1, ${count}]'!"
      return 1
    else
      echo "${array["${quick_select_index}"]}"
    fi
  }

  if ! isRootSet; then
    echoerr "ZK_CODE_ROOT is not defined!"
    return 1
  fi # ZTODO: This might be a good spot for the usage.

  if ! validateArguments "${@}"; then
    echoerr "Failed to validate arguments!"
    return 1
  fi

  if [ "${1}" = "${quick_select_root}" ]; then
    cd "${ZK_CODE_ROOT}"
    return 0
  fi

  local quick_select_org_index="$(parseQuickSelectArgument "${1}")"
  if [ -z "${quick_select_org_index}" ]; then
    return 1
  fi

  local quick_select_repo_index="$(parseQuickSelectArgument "${2}")"
  if [ -z "${quick_select_repo_index}" ]; then
    return 1
  fi

  local orgs=($(statOrgs))
  local orgs_section_header="-----Orgs-----"
  local selected_org="$(produceSelectionIndex "${quick_select_org_index}" "${orgs_section_header}" "${orgs[@]}")"
  if [ -z "${selected_org}" ]; then
    return 1
  fi

  local repos=($(statRepos "${selected_org}"))
  local repos_section_header="\n-----Repos-----"
  local selected_repo="$(produceSelectionIndex "${quick_select_repo_index}" "${repos_section_header}" "${repos[@]}")"
  if [ -z "${selected_repo}" ]; then
    return 1
  fi

  cd "${ZK_CODE_ROOT}/${selected_org}/${selected_repo}"
}

function_redefine repeat_until_fail
function repeat_until_fail() {
  RED='\033[0;31m'
  CYAN='\033[0;36m'
  NO_COLOR='\033[0m'

  iteration=0
  last_code=0
  while [ $last_code -eq 0 ]; do
    iteration=$((iteration+1))
    echo -e "${CYAN}--- Starting itaration $iteration ---${NO_COLOR}"
    eval "$1"
    last_code=$?
  done

  echo -e "${RED}--- Last command failed with code ${last_code} on iteration ${iteration} ---${NO_COLOR}"
}
