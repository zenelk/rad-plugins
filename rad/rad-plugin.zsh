function rad {
    case "$1" in
        reload)
            shift
            _rad_reload "$@"
            ;;
        edit)
            _rad_edit
            ;;
        *)
            echo "Unrecognized verb: $1"
            return 1
            ;;
    esac
}

function _rad_reload {
    if ! _check_workspace; then
        return 1
    fi

    if [ "$1" = "-d" ]; then
        echo "Reloading as debug!"
        set -x
    fi

    all_plugins=$(find \
        -HL \
        "$ZK_RAD_PLUGINS_WORKSPACE" \
        -not -path "*/.git/*" \
        -iname "*.zsh")

    while read -r line; do
        echo "Reloading plugin: $line"
        source "$line"
    done <<<"$all_plugins"

    if [ "$1" = "-d" ]; then
        set +x
    fi
}

function _rad_edit {
    if ! _check_workspace; then
        return 1
    fi

    subl "$ZK_RAD_PLUGINS_WORKSPACE"
}

function _check_workspace {
    if [ ! -d "$ZK_RAD_PLUGINS_WORKSPACE" ]; then
        echo "Could not find rad-plugins workspace! Did you set ZK_RAD_PLUGINS_WORKSPACE?"
        return 1
    fi
    return 0
}