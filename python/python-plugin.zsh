ZK_VENV_ROOT="${HOME}/.venv"

function_redefine venv
function venv() {
  function _venv_usage() {
    echo "Usage: venv [verb] [options]"
    echo "  [verb] (default: list) is one of:"
    echo "    activate   (a)"
    echo "    create     (c)"
    echo "    deactivate (da)"
    echo "    destroy    (d)"
    echo "    help       (h)"
    echo "    list       (l)"
    echo "    recreate   (r)"
    echo "  [options] are arguments defined in the respective verbs"
  }

  if [ -z "${1}" ]; then
    _venv_usage
    return 1
  fi

  local verb="${1}"
  shift

  case "${verb}" in
    'activate' | 'a')
      _venv_activate "${@}"
      ;;
    'create' | 'c')
      _venv_create "${@}"
      ;;
    'destroy' | 'd')
      _venv_destroy "${@}"
      ;;
    'deactivate' | 'da')
      _venv_deactivate "${@}"
      ;;
    '' | 'help' | 'h')
      _venv_usage
      ;;
    'list' | 'l')
      _venv_list "${@}"
      ;;
    'recreate' | 'r')
      _venv_recreate "${@}"
      ;;
    *)
      echo "Invalid verb: '${verb}'!"
      _venv_usage
      return 1
      ;;
  esac
}

function_redefine _inside_venv
function _inside_venv() {
  if [[ "$(command -v python)" =~ ${ZK_VENV_ROOT}/.* ]]; then
    return 0
  else
    return 1
  fi
}

function_redefine _current_venv_name
function _current_venv_name() {
  if _inside_venv; then
    command -v python | sed "s|${ZK_VENV_ROOT}/||" | cut -d '/' -f2
  else
    echo ""
  fi
}

function_redefine _python_version
function _python_version() {
  python --version | cut -d ' ' -f 2
}

function_redefine _venv_deactivate_if_inside
function _venv_deactivate_if_inside() {
  if _inside_venv; then
    local current_venv_name="$(_current_venv_name)"
    echo "Already inside Python virtual environment '${current_venv_name}'. Deactivating..."
    _venv_deactivate
  fi
}

function_redefine _venv_activate
function _venv_activate() {
  function _venv_activate_usage() {
    echo "Usage: venv activate VENV_NAME"
  }

  _venv_deactivate_if_inside

  local target_venv_name="${1}"
  if [ -z "${target_venv_name}" ]; then
    echo "Missing target virtual environment name!"
    _venv_activate_usage
    return 1
  fi

  echo "Activating Python virtual environment '${target_venv_name}'..."

  python_version="$(_python_version)"
  if ! source "${ZK_VENV_ROOT}/${python_version}/${target_venv_name}/bin/activate"; then
    echo "Failed to activate Python virtual environment '${target_venv_name}'!"
    return 2
  fi
}

function_redefine _venv_create
function _venv_create() {
  function _venv_create_usage() {
    echo "Usage: venv create VENV_NAME"
  }

  local target_venv_name="${1}"
  if [ -z "${target_venv_name}" ]; then
    echo "Missing target virtual environment name!"
    _venv_create_usage
    return 1
  fi

  local python_version="$(_python_version)"
  local venv_path="${ZK_VENV_ROOT}/${python_version}/${target_venv_name}"
  if [ -d "${venv_path}" ]; then
    echo "Python virtual environment '${target_venv_name}' already exists!"
    return 2
  fi

  echo "Creating Python virtual environment '${target_venv_name}'..."
  if ! python -m venv "${venv_path}"; then
    echo "Failed to create Python virtual environment '${target_venv_name}'!"
    return 3
  fi
}

function_redefine _venv_deactivate
function _venv_deactivate() {
  local current_venv_name="$(_current_venv_name)"
  echo "Deactivating Python virtual environment '${current_venv_name}'..."
  if ! deactivate; then
    echo "Failed to deactivate Python virtual environment '${current_venv_name}'!"
    return 1
  fi
}

function_redefine _venv_destroy
function _venv_destroy() {
  function _venv_destroy_usage() {
    echo "Usage: venv destroy VENV_NAME"
  }

  local target_venv_name="${1}"
  if [ -z "${target_venv_name}" ]; then
    echo "Missing target virtual environment name!"
    _venv_destroy_usage
    return 1
  fi

  local python_version="$(_python_version)"
  local venv_path="${ZK_VENV_ROOT}/${python_version}/${target_venv_name}"

  echo "Destroying Python virtual environment '${target_venv_name}'..."
  if ! rm -rf "${venv_path}"; then
    echo "Failed to destroy Python virtual environment '${target_venv_name}'!"
    return 3
  fi
}

function_redefine _venv_list
function _venv_list() {
  local python_version="$(_python_version)"
  local venvs_path="${ZK_VENV_ROOT}/${python_version}"

  echo "Python virtual environments for Python version ${python_version}:"
  for venv in $(ls -1 "${venvs_path}" | grep -v -e '^\.$' -e '^\.\.$'); do
    echo "  ${venv}"
  done
}

function_redefine _venv_recreate
function _venv_recreate() {
  function _venv_recreate_usage() {
    echo "Usage: venv recreate VENV_NAME"
  }

  local target_venv_name="${1}"
  if [ -z "${target_venv_name}" ]; then
    echo "Missing target virtual environment name!"
    _venv_recreate_usage
    return 1
  fi

  _venv_destroy "${target_venv_name}"
  _venv_create "${target_venv_name}"
}

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
    python3 -m black $@
    if [ $? -ne 0 ]; then
      echo -e "\e[31mBlack failed!\e[0m\n" >&2
    else
      echo -e "\e[35mBlack succeeded!\e[0m\n"
    fi
  fi

  if [ "$do_mypy" = true ]; then
    echo "Running Mypy with args '$@'..."
    python3 -m mypy --exclude build --strict $@
    if [ $? -ne 0 ]; then
      echo -e "\e[31mMypy failed!\e[0m\n" >&2
    else
      echo -e "\e[35mMypy succeeded!\e[0m\n"
    fi
    fi

    if [ "$do_pytest" = true ]; then
    echo "Running Pytest with args '$@'..."
    if [ -d "$1/src" ]; then
      src_cov_term="--cov=src"
    fi
    python3 -m pytest $@ --cov-report term-missing $src_cov_term --tb=auto -l -rPx
    if [ $? -ne 0 ]; then
      echo -e "\e[31mPytest failed!\e[0m\n" >&2
    else
      echo -e "\e[35mPytest succeeded!\e[0m\n"
    fi
  fi
}
