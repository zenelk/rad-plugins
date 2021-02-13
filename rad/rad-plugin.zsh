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
    # ZTODO: Probably should make these options better...
    if [ "$1" = '-d' ]; then
        echo "Reloading as debug!"
        set -x
    fi

    if ! _rad_check_workspace; then
        return 1
    fi

    local rad_plugins_file
    rad_plugins_file="$ZK_RAD_PLUGINS_WORKSPACE/.rad-plugins"
    if [ -z "$rad_plugins_file" ]; then
        echo "Could not find .rad-plugins file at '$rad_plugins_file'"
        return 2
    fi

    local org
    local plugin_name
    local plugin_path
    while read -r line; do
        if _rad_is_comment_or_blank "$line"; then
            continue
        fi

        org="$(_rad_parse_org "$line")"
        plugin_name="$(_rad_parse_plugin_name "$line")"
        plugin_path="$ZK_RAD_PLUGINS_WORKSPACE/$org/$plugin_name/$plugin_name-plugin.zsh"

        if [ -f "$plugin_path" ]; then
            source "$plugin_path"
        elif [ "$1" = '-d' ]; then
            echo "Not reloading '$plugin_path', source not found in workspace..."
        fi
    done <"$rad_plugins_file"

    if [ "$1" = '-d' ]; then
        set +x
    fi
}

function _rad_edit {
    if ! _rad_check_workspace; then
        return 1
    fi

    subl "$ZK_RAD_PLUGINS_WORKSPACE"
}

function _rad_check_workspace {
    if [ ! -d "$ZK_RAD_PLUGINS_WORKSPACE" ]; then
        echo "Could not find rad-plugins workspace! Did you set ZK_RAD_PLUGINS_WORKSPACE?"
        return 1
    fi
    return 0
}

function _rad_is_comment_or_blank {
    [[ "$1" =~ '^#.*$|^\s?$' ]]
}

function _rad_parse_org {
    [[ "$1" =~ '^(.*)/.*$' ]] && echo "${match[1]#*:}"
}

function _rad_parse_plugin_name {
    [[ "$1" =~ '^.* (.*)$' ]] && echo "${match[1]}"
}