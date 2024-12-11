function_redefine nuke
function nuke() {
  case "$1" in
    git)
      _nuke_git
      ;;
    docker)
      _nuke_docker
      ;;
    xcode)
      _nuke_xcode
      ;;
    carthage)
      shift 1
      _nuke_carthage "$@"
      ;;
    fastlane)
      _nuke_fastlane
      ;;
    python)
      shift 1
      _nuke_python "$@"
      ;;
    *)
      echo "Invalid target: $1"
      return 1
      ;;
  esac
}

# TODO: Would sure be nice to module load this somehow. Don't have time right now for that.
function_redefine _nuke_docker
function _nuke_docker() {
  docker rm -fv $(docker ps -aq)
}

function_redefine _nuke_xcode
function _nuke_xcode() {
  killall Xcode; rm -rf ~/Library/Developer/Xcode/DerivedData
}

function_redefine _nuke_git
function _nuke_git() {
  current_dir=$(pwd)
  git_root=$(git rev-parse --show-toplevel)
  changed_directories=false
  if [[ $current_dir != $git_root ]]; then
    changed_directories=true
    pushd "$git_root"
  fi
  git submodule foreach --recursive git clean -fd
  git submodule foreach --recursive git checkout -f --
  git submodule update
  git clean -fd
  git checkout -f --
  if [[ $changed_directories = true ]]; then
    popd
  fi
}

function_redefine _nuke_carthage
function _nuke_carthage() {
  local clean_all=false
  # In zsh, you have to not quote this or else you break the numeric parsing.
  while (( $# )); do
    case "${1}" in
      -a|--all)
        clean_all=true
        shift 1
        ;;
      *)
        echo "Unrecognized argument: '${1}'!"
        exit 2
      ;;
    esac
  done

  if [ "${clean_all}" = true ]; then
    rm -rf ~/Library/Caches/org.carthage.CarthageKit
    rm -rf ~/Library/Caches/Rome
  fi
  find . -iname "Carthage" | head -n 1 | xargs rm -rf
}

function_redefine _nuke_fastlane
function _nuke_fastlane() {
  rm -rf fastlane/output
}

function_redefine _nuke_python
function _nuke_python() {
  if [ -z "${ZK_VENV_ROOT}" ]; then
    echo "ZK_VENV_ROOT is not set! Refusing to nuke an undefined target!"
    return 1
  fi

  local clean_all=false
  # In zsh, you have to not quote this or else you break the numeric parsing.
  while (( $# )); do
    case "${1}" in
      -a|--all)
        clean_all=true
        shift 1
        ;;
      *)
        echo "Unrecognized argument: '${1}'!"
        return 2
      ;;
    esac
  done

  if ! command -v deactivate; then
    echo "No active virtual environment to deactivate."
  else
    echo "Deactivating active virtual environment..."
    deactivate
  fi

  echo "Removing all virtual environments in '${ZK_VENV_ROOT}'..."
  rm -rf "${ZK_VENV_ROOT}"

  if [ "${clean_all}" = true ]; then
    echo "All argument was specified. Are you sure you want to end the world? [y/N]"
    read -r response
    if [ "${response}" != "y" ]; then
      echo "Good call. No ending the world today."
      return 1
    fi

    all_python_versions=$(pyenv versions --bare)
    echo "Removing all Python versions and their virtual environments..."
    echo "${all_python_versions}" | while read -r python_version; do
      pyenv uninstall -f "${python_version}"
    done
  fi
}
