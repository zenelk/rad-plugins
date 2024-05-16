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
    return 1
  else
    echo "${branches}"
  fi

  if [[ "${1}" = '-d' ]]; then
    echo "${branches}" | xargs git branch -D
  fi
  return 0
}

function_redefine gbcl
function gbcl() {
  echo "Fetching..."
  gf

  echo "Pulling from origin..."
  gl

  if [ "$(git remote | wc -l)" -gt 1 ]; then
    echo "Found more than one remote, also pulling in upstream..."
    gl upstream "$(gb)"
  fi

  echo "Pushing current branch..."
  gp

  echo "Starting gone branch cleanup..."
  gbnr
  exit_code=$?
  if [ $exit_code -eq 0 ]; then
    echo "Do you want to remove these branches? (y/n)"
    read -r response
    if [ "${response,,}" = "y" ]; then
      gbnr -d
    else
      echo "Branches not removed."
    fi
  fi

  echo "Done."
}
