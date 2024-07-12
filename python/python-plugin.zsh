function_redefine pyv
function pyv() {
  do_black=false
  do_mypy=false
  do_pytest=false
  should_shift=false

  while getopts "bmp" opt; do
    case $opt in
      b)
        echo "Option -b: $OPTARG"
        do_black=true
        should_shift=true
        ;;
      m)
        echo "Option -m: $OPTARG"
        do_mypy=true
        should_shift=true
        ;;
      p)
        echo "Option -p: $OPTARG"
        do_pytest=true
        should_shift=true
        ;;
      \?)
        echo "Invalid option: -$OPTARG" >&2
        return 1
        ;;
    esac
  done

  if [ "$should_shift" = true ]; then
    shift $((OPTIND - 1))
  fi

  if [ -z "$1" ]; then
    echo "Usage: pyv [-b] [-m] [-p] PATH..." >&2
    return 1
  fi

  if [ "$do_black" = false ] && [ "$do_mypy" = false ] && [ "$do_pytest" = false ]; then
    do_black=true
    do_mypy=true
    do_pytest=true
  fi

  if [ "$do_black" = true ]; then
    echo "Running Black with args '$@'..."
    black "$@"
    if [ $? -ne 0 ]; then
      echo -e "blk command failed!\n" >&2
    else
      echo -e 'Black succeeded!\n'
    fi
  fi

  if [ "$do_mypy" = true ]; then
    echo "Running Mypy with args '$@'..."
    mypy --exclude build --strict "$@"
    if [ $? -ne 0 ]; then
      echo -e "smp command failed!\n" >&2
    else
      echo -e 'Mypy succeeded!\n'
    fi
  fi

  if [ "$do_pytest" = true ]; then
    echo "Running Pytest with args '$@'..."
    pytest "$@" --cov-report term-missing --cov=src --tb=auto -l -rPx
    if [ $? -ne 0 ]; then
      echo -e "pyt command failed!\n" >&2
    else
      echo -e 'Pytest succeeded!\n'
    fi
  fi
}
