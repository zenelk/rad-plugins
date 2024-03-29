# Check out branches easier
function_redefine gcb
function gcb() {
  local branches=()
  for branch in $(git for-each-ref --format='%(refname:short)' refs/heads/); do
    branches+=("$branch")
  done

  # TODO: Left off with refactor here

  containsElement () {
    local e match="$1"
    shift
    for e; do [[ "$match" =~ "$e" ]] && return 1; done
    return 0
  }

  local special_branches=()
  local other_branches=()
  for branch in "${branches[@]}"; do
    containsElement "$branch" "${SPECIAL_BRANCHES[@]}"
    local special="$?"
    if [ $special -ne 0 ]; then
      special_branches+=("$branch")
    else
      other_branches+=("$branch")
    fi
  done

  local sorted_special_branches_string="$(echo ${special_branches[@]} | tr ' ' '\n' | sort -r)"
  local special_branches_sorted=()
  while read -r line; do special_branches_sorted+=("$line"); done <<<"$sorted_special_branches_string"

  if [ ${#other_branches[@]} -ne 0 ]; then
    local sorted_other_branches_string="$(echo ${other_branches[@]} | tr ' ' '\n' | sort -r)"
    local other_branches_sorted=()
    while read -r line; do other_branches_sorted+=("$line"); done <<<"$sorted_other_branches_string"
    local all_sorted=("${special_branches_sorted[@]}" "${other_branches_sorted[@]}")
  else
    local all_sorted=("${special_branches_sorted[@]}")
  fi

  local branch_count="${#all_sorted[@]}"

  local selection="${1}"
  if [ -z "$selection" ]; then
    local i=1
    for branch in "${all_sorted[@]}"; do
      echo "${i}) ${branch}"
      i=$((i+1))
    done

    while [ -z "${selection}" ]; do
      printf "Enter number to switch to [1-$branch_count]: "
      read input
      case "$input" in
        ''|*[!0-9]*)
          echo "Not a number! Try again..."
          ;;
        *)
          if [ $input -lt 1 ] || [ $input -gt $branch_count ]; then
            echo "Out of bounds! Try again..."
          else
            selection="$input"
          fi
          ;;
      esac
    done
  elif [[ ! $selection =~ '^[0-9]+$' ]] || [ $selection -lt 1 ] || [ $selection -gt $branch_count ]; then
    echo "Quick checkout failed: Branch index out of bounds!"
    return 1
  fi

  local invocation=(git checkout)
  if [ ! -z $force ]; then
    invocation+=("-f")
  fi
  invocation+="${all_sorted[$selection]}"
  "${invocation[@]}"
}