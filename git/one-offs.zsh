function_redefine sublconflicts
function sublconflicts() {
  IFS=$'\n'
  files=($(git ls-files -u \
    | cut -f2 \
    | uniq))
  IFS=' '
  subl -n "${files[@]}"
}

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
