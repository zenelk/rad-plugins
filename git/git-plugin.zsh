SPECIAL_BRANCHES=("develop" "master" "RC-*" "release/*")

alias ga='git add -A'
alias gf='git fetch --all --prune'
alias gs='git status'
alias gd='git diff'
alias gdc='git diff --cached'
alias gp='git push'
alias gl='git pull'
alias gld='git pull origin develop'
alias gpu='git push -u origin `gb`'
alias gh='git rev-parse HEAD'
alias gb='git rev-parse --abbrev-ref HEAD'
alias gc='git commit'
alias ggg="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) \
- %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n''          \
%C(white)%s%C(reset) %C(dim white)- %an%C(reset)' --all"

git config --global core.preloadindex true
git config --global core.fscache true
git config --global gc.auto 256

function sublconflicts() {
    IFS='
'
    for file in $(git ls-files -u | cut -f2 | uniq); do
        subl "$file"
    done
}

function gdb() {
    git branch -D $1
    git push origin :$1
}

function gfs() {
    git flow feature start $1
    gpd
}

function grc() {
    git add -A
    git commit --amend --no-edit
    git push -f
}

function gitnuke() {
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

function glb() {
    git branch -vv | cut -c 3- | awk '$3 !~/\[/ { print $1 }'
}

# Check out branches easier
function gcb() {
    usage() { echo "Usage: $0 [-r] [-f]" 1>&2; return 1; }

    local selection=""

    while getopts ":rf" o; do
        case "${o}" in
            r)
                local remote=1
                ;;
            f)
                local force=1
                ;;
            [0-9]*)

                ;;
            *)
                return usage
                ;;
        esac
    done
    shift $((OPTIND-1))

    if [ ! -z $1 ]; then
        case "$1" in
            ''|*[!0-9]*)
                echo "Quick checkout failed: Not a number!"
                return usage
                ;;
            *)
                selection="$1"
                ;;
        esac
        selection="$1"
    fi

    local branches=()
    if [ -z "${remote}" ]; then
        local branches_string="$(git for-each-ref --format='%(refname:short)' refs/heads/)"
        if [ -z "$branches_string" ]; then
            return 2
        fi
        while read -r line; do branches+=("$line"); done <<<"$branches_string"
    else
        local branches_string="$(git ls-remote --heads origin | cut -f2 | sed -e "s/^refs\/heads\///")"
        if [ -z "$branches_string" ]; then
            return 2
        fi
        while read -r line; do branches+=("$line"); done <<<"$branches_string"
    fi

    containsElement () {
        local e match="$1"
        shift
        for e; do [[ "$match" =~ "$e" ]] && return 1; done
        return 0
    }

    local special_branches=()
    local other_branches=()
    for branch in "${branches[@]}"; do
        containsElement "$branch" "${SPECIAL_BRANCHES[@]}"
        local special="$?"
        if [ $special -ne 0 ]; then
            special_branches+=("$branch")
        else
            other_branches+=("$branch")
        fi
    done

    local sorted_special_branches_string="$(echo ${special_branches[@]} | tr ' ' '\n' | sort -r)"
    local special_branches_sorted=()
    while read -r line; do special_branches_sorted+=("$line"); done <<<"$sorted_special_branches_string"

    if [ ${#other_branches[@]} -ne 0 ]; then
        local sorted_other_branches_string="$(echo ${other_branches[@]} | tr ' ' '\n' | sort -r)"
        local other_branches_sorted=()
        while read -r line; do other_branches_sorted+=("$line"); done <<<"$sorted_other_branches_string"
        local all_sorted=("${special_branches_sorted[@]}" "${other_branches_sorted[@]}")
    else
        local all_sorted=("${special_branches_sorted[@]}")
    fi

    local branch_count="${#all_sorted[@]}"

    if [ -z "$selection" ]; then
        local i=1
        for branch in "${all_sorted[@]}"; do
            echo "${i}) ${branch}"
            i=$((i+1))
        done

        while [ -z "${selection}" ]; do
            printf "Enter number to switch to [1-$branch_count]: "
            read input
            case "$input" in
                ''|*[!0-9]*)
                    echo "Not a number! Try again..."
                    ;;
                *) 
                    if [ $input -lt 1 ] || [ $input -gt $branch_count ]; then
                        echo "Out of bounds! Try again..."
                    else
                        selection="$input"
                    fi
                    ;;
            esac
        done
    else
        if [ $selection -lt 1 ] || [ $selection -gt $branch_count ]; then
            echo "Quick checkout failed: Branch index out of bounds!"
            return 1
        fi
    fi

    local invocation=(git checkout)
    if [ ! -z $force ]; then
        invocation+=("-f")
    fi
    invocation+="${all_sorted[$selection]}"
    "${invocation[@]}"
}

# Clean up local branches
function trimbranches() {
    local safe_branch='master'
    echo "First getting to a safe branch, using '${safe_branch}'."
    local starting_branch="$(git rev-parse --abbrev-ref HEAD)"
    git checkout master

    local branches_string="$(git for-each-ref --format='%(refname:short)' refs/heads/)"
    if [ -z "$branches_string" ]; then
        echo "No branches?"
        return 1
    fi
    local branches=()
    while read -r line; do branches+=("$line"); done <<<"$branches_string"

    containsElement () {
        local e match="$1"
        shift
        for e; do [[ "$match" =~ "$e" ]] && return 1; done
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

    if [ $deleted_starting_branch != true ]; then
        echo "Returning to the starting branch: '${starting_branch}'"
        git checkout "${starting_branch}"
    fi
}
