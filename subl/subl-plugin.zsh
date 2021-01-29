# Add subl ignore for history
export ZK_HIST_IGNORE_REGEX="${ZK_HIST_IGNORE_REGEX}|^subl"

unamestr=$(uname)

if [ $unamestr = "Darwin" ]; then
	export PATH="$PATH:/Applications/Sublime Text.app/Contents/SharedSupport/bin"
else
	echo "Unsupported OS ($unamestr) for setting up 'subl'!"
fi
