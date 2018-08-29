if [ -v BASH_SOURCE ]; then
	THIS=${BASH_SOURCE[0]}
elif [ -v ZSH_VERSION ]; then
	THIS=${(%):-%x}
else
	THIS=$0
fi

THISDIR=$( cd $(dirname $THIS) > /dev/null ; pwd -P )

if [ -z $1 ]; then
	echo 'python interpreter not specified, using "python"'
	PYD_PYTHON=python
else
	PYD_PYTHON=$1
fi

eval $($PYD_PYTHON $THISDIR/pyd_get_env_set_text.py)
