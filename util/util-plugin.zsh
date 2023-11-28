alias myip="ifconfig en0 | grep inet | grep -v inet6 | awk '{printf \"%s\", \$2}'"
alias ls='ls -al'
alias kx='killall Xcode'

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
  function echoerr() {
    echo $@ >&2
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

  if [ -z "${ZK_CODE_ROOT}" ]; then
    echoerr "ZK_CODE_ROOT is not defined!"
    return 1
  fi

  if [ "${1}" = "-" ]; then
    cd "${ZK_CODE_ROOT}"
    return 0
  elif [[ "${1}" =~ '^[0-9]+,[0-9]+$' ]]; then
    local quick_select_org_index="$(echo "${1}" | cut -d ',' -f 1)"
    local quick_select_repo_index="$(echo "${1}" | cut -d ',' -f 2)"
  elif [ ! -z "${1}" ]; then
    echoerr "Unsupported argument: '${1}'"
    return 1
  fi

  local orgs=($(statOrgs))
  local selected_org
  if [ -z "${quick_select_org_index}" ]; then
    echoerr "-----Orgs-----"
    echoFormattedPromptArray "${orgs[@]}"
    selected_org="$(readSelectionInputFromArray "${orgs[@]}")"
  else
    local count="${#orgs[@]}"
    if [ "${quick_select_org_index}" -lt 1 ] || [ "${quick_select_org_index}" -gt "${count}" ]; then
      echoerr "Quick select org index '${quick_select_org_index}' out of bounds '[1, ${count}]'!"
      return 1
    fi
    selected_org="${orgs["${quick_select_org_index}"]}"
  fi

  local repos=($(statRepos "${selected_org}"))
  local selected_repo
  if [ -z "${quick_select_repo_index}" ]; then
    echoerr -e "\n-----Repos-----"
    echoFormattedPromptArray "${repos[@]}"
    selected_repo="$(readSelectionInputFromArray "${repos[@]}")"
  else
    local count="${#repos[@]}"
    if [ "${quick_select_repo_index}" -lt 1 ] || [ "${quick_select_repo_index}" -gt "${count}" ]; then
      echoerr "Quick select repo index '${quick_select_repo_index}' out of bounds '[1, ${count}]'!"
      return 1
    fi
    selected_repo="${repos["${quick_select_repo_index}"]}"
  fi

  cd "${ZK_CODE_ROOT}/${selected_org}/${selected_repo}"
}
