# TODO: Need to take remotes into account.
SPECIAL_BRANCHES=("develop" "master" "RC-*" "release/*")

# Clean up local branches
function trimbranches() {
    git fetch --all --prune
    if [ "$1" = "-f" ]; then
        local force=true
    fi

    if [ "$force" = false ]; then
        local remote_branches_string="$(git for-each-ref --format='%(refname:lstrip=3)' refs/remotes/) $(git for-each-ref --format='%(refname:lstrip=2)' refs/remotes/)"
        if [ -z "$remote_branches_string" ]; then
            echo "No remote branches?"
            return 1
        fi
        local remote_branches=()
        while read -r line; do remote_branches+=("$line"); done <<<"$remote_branches_string"
    fi

    local branches_string="$(git for-each-ref --format='%(refname:lstrip=2)' refs/heads/)"
    if [ -z "$branches_string" ]; then
        echo "No branches?"
        return 1
    fi
    local branches=()
    while read -r line; do
        local should_skip=false
        for remote_branch in "${remote_branches[@]}"; do
            if [ "$remote_branch" = "$line" ]; then
                should_skip=true
                break
            fi
        done
        if [ "$should_skip" = false ]; then
            branches+=("$line")
        fi
    done <<<"$branches_string"

    if [ "${#branches[@]}" -le 0 ]; then
        echo "No matching branches were found with the given criteria."
        return 0
    fi

    containsElement() {
        local e match="$1"
        shift
        for e; do [[ "$match" =~ $e ]] && return 1; done
        return 0
    }

    _ask_delete_branch() {
        while [ 1 ]; do
            printf "Delete branch '$1'? (y/n): "
            read input
            case "$input" in
                y)
                    echo "Deleting branch: '$1'"
                    git branch -D "$1"
                    return 1
                    ;;
                n)
                    echo "Not deleting branch: '$1'"
                    return 0
                    ;;
                *)
                    echo "Enter 'y' or 'n'."
                    ;;
            esac
        done
    }


    local safe_branch='origin/master'
    echo "First getting to a safe branch, using '${safe_branch}'."
    local starting_branch="$(git rev-parse --abbrev-ref HEAD)"
    git checkout "$safe_branch"

    local deleted_starting_branch=false
    for branch in "${branches[@]}"; do
        containsElement "$branch" "${SPECIAL_BRANCHES[@]}"
        local special="$?"
        if [ $special -eq 0 ]; then
            _ask_delete_branch "$branch"
            local deleted_branch="$?"
            if [ $deleted_branch -eq 1 ]; then
                if [ $branch = $starting_branch ]; then
                    echo "Note: You deleted your starting branch! You will be left on the safe branch (${safe_branch})."
                    deleted_starting_branch=true
                fi
            fi
        else
            echo "Ignoring special branch: ${branch}"
        fi
    done

    if [ "$deleted_starting_branch" != true ]; then
        echo "Returning to the starting branch: '${starting_branch}'"
        git checkout "${starting_branch}"
    fi
}
