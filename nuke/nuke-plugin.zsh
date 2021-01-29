export ZK_HIST_IGNORE_REGEX="${ZK_HIST_IGNORE_REGEX}|^nuke"

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
        *)
			echo "Invalid target: $1"
			return 1
            ;;
    esac
}

# TODO: Would sure be nice to module load this somehow. Don't have time right now for that.
function _nuke_docker() {
	docker rm -fv $(docker ps -aq)
}

function _nuke_xcode() {
	killall Xcode; rm -rf ~/Library/Developer/Xcode/DerivedData
}

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