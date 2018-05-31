unamestr=$(uname)

if [ $unamestr = "Darwin" ]; then
	export PATH="$PATH:/Applications/Sublime Text.app/Contents/SharedSupport/bin"
else
	echo "Unsupported OS ($unamestr) for setting up 'subl'!"
fi
