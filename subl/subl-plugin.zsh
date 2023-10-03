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

function_redefine sur
function sur() {
  sr $@ && subl .
}
