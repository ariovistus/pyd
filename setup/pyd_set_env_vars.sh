main() {
	if [ -v BASH_SOURCE ]; then
		local -r THIS=${BASH_SOURCE[0]}
	elif [ -v ZSH_VERSION ]; then
		local -r THIS=${(%):-%x}
	else
		local -r THIS=$0
	fi

	local -r THISDIR=$( cd $(dirname $THIS) > /dev/null ; pwd -P )

	if [ -z $1 ]; then
		echo 'python interpreter not specified, using "python"'
		local -r PYD_PYTHON=python
	else
		local -r PYD_PYTHON=$1
	fi

	eval $($PYD_PYTHON $THISDIR/pyd_get_env_set_text.py)
}

main
