unamestr=$(uname)

if [ $unamestr = "Darwin" ]; then
  export PATH="$PATH:/Applications/Sublime Text.app/Contents/SharedSupport/bin"
else
  echo "Unsupported OS ($unamestr) for setting up 'subl'!"
fi

function_redefine sublconflicts
function sublconflicts() {
  IFS=$'\n'
  files=($(git ls-files -u \
    | cut -f2 \
    | uniq))
  IFS=' '
  subl -n "${files[@]}"
}

function_redefine sublrepo
function sublrepo() {
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
    subl "${ZK_CODE_ROOT}"
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

  subl "${ZK_CODE_ROOT}/${selected_org}/${selected_repo}"
}

alias sr='sublrepo'
