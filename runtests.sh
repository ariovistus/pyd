#!/bin/bash

set -e
$PYTHON setup.py install
$PYTHON runtests.py $RUNSPEC --clean
$PYTHON runtests.py $RUNSPEC --compiler $COMPILER

dub test --config=$DUBCONFIG
source setup/pyd_set_env_vars.sh $PYTHON && dub test -c env
