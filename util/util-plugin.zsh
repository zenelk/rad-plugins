alias myip="ifconfig en0 | grep inet | grep -v inet6 | awk '{printf \"%s\", \$2}'"
alias ls='ls -al'

function_redefine cdup
function cdup() {
    if ! [[ $1 =~ '^[0-9]+$' && $1 > 0 ]]; then
        echo "Entered value is invalid: $1"
        return 1
    fi
    for i in $(seq 1 $1); do
        cd ..
    done
}
