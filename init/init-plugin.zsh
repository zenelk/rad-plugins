# Allows for functions to be reloaded when used like so:
# function_redefine foo
# function foo() { ... }
function_redefine() {
    while (( $# )); do
        if function_exists "$1"; then
            unfunction "$1"
        fi
        autoload -U "$1"
        shift
    done
}

function_exists() {
    declare -f "$1" > /dev/null
}
