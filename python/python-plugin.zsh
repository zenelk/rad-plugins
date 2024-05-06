alias blk='black .'
alias smp='mypy --exclude build --strict .'

function_redefine pyt
function pyt() {
  pytest "$@" --cov-report term-missing --cov=src --tb=auto -l -rPx
}

function_redefine pyv
function pyv() {
  echo 'Running Black...'
  blk
  if [ $? -ne 0 ]; then
    echo -e "blk command failed!\n" >&2
  else
    echo -e 'Black succeeded!\n'
  fi

  echo 'Running Mypy...'
  smp
  if [ $? -ne 0 ]; then
    echo -e "smp command failed!\n" >&2
  else
    echo -e 'Mypy succeeded!\n'
  fi

  echo 'Running Pytest...'
  pyt
  if [ $? -ne 0 ]; then
    echo "pyt command failed!" >&2
  else
    echo 'Pytest succeeded!'
  fi
}
