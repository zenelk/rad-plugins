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