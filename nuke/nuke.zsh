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