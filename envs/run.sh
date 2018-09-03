#docker run -v$(pwd)/../:/src -e "COMPILER=dmd" -e "RUNSPEC=runtests" -e "PYTHON=python3.4" -e "DUBCONFIG=python34" -t jess bash runtests.sh
#docker run -v$(pwd)/../:/src -e "COMPILER=dmd" -e "RUNSPEC=runtests" -e "PYTHON=python3.4" -e "DUBCONFIG=python34" -it jess bash 
docker run -v$(pwd)/../:/src -e "COMPILER=gdc" -e "RUNSPEC=runtests:PydUnittests.test_struct_wrap" -e "PYTHON=python3.7" -e "DUBCONFIG=python37" -it ariovistus/pyd-test-env:stretch-gdc63-py37 bash  runtests.sh
#docker run -v$(pwd)/../:/src -e "COMPILER=gdc" -e "RUNSPEC=runtests" -e "PYTHON=python3.7" -e "DUBCONFIG=python37" -it lass bash 
