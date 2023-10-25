function_redefine gdb
function gdb() {
  if [ -z "$1" ]; then
    echo "Branch name is required!"
    return
  fi
  git branch -D "$1"
  git push origin ":$1"
}

function_redefine grc
function grc() {
  git add -A
  git commit --amend --no-edit
  git push -f
}

function_redefine gbnr
function gbnr() {
  if [[ "${1}" = '-d' ]]; then
    echo -e "Deleting the following branches locally:"
  fi

  local branches="$(git branch -vv | cut -c 3- | grep ': gone]' | awk '{print $1}')"
  
  if [[ -z "${branches}" ]]; then
    echo "No branches found locally that are removed from the remote."
    return 0
  else
    echo "${branches}"
  fi

  if [[ "${1}" = '-d' ]]; then
    echo "${branches}" | xargs git branch -D
  fi
}
