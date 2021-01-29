# Add myip/cdup ignores for history
export ZK_HIST_IGNORE_REGEX="${ZK_HIST_IGNORE_REGEX}|^myip ?$|^cdup ?$"

alias myip="ifconfig en0 | grep inet | grep -v inet6 | awk '{printf \"%s\", \$2}'"

function cdup {
	if ! [[ $1 =~ '^[0-9]+$' && $1 > 0 ]]; then
		echo "Entered value is invalid: $1"
		return 1
	fi
	for i in $(seq 1 $1); do
		cd ..
	done
}