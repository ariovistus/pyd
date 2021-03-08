#!/===you-must-source-this-script===/

main_b97532fa() {
	if [ -v BASH_SOURCE ]; then
		local THIS=${BASH_SOURCE[0]}
	elif [ -v ZSH_VERSION ]; then
		local THIS=${(%):-%x}
	else
		local THIS=$0
	fi

	local THISDIR
	THISDIR=$( cd "$(dirname "$THIS")" > /dev/null ; pwd -P ) || return 1

	if [ $# -eq 0 ]; then
		echo 'python interpreter not specified, using "python"'
		local PYD_PYTHON=python
	else
		local PYD_PYTHON=$1
	fi

	eval "$($PYD_PYTHON "$THISDIR"/pyd_get_env_set_text.py)"
}

main_b97532fa "$@"
