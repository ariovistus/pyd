docker run -v$(pwd)/../:/src -e "COMPILER=dmd" -e "RUNSPEC=runtests" -e "PYTHON=python3.4" -e "DUBCONFIG=python34" -t jess bash runtests.sh
#docker run -v$(pwd)/../:/src -e "COMPILER=dmd" -e "RUNSPEC=runtests" -e "PYTHON=python3.4" -e "DUBCONFIG=python34" -it jess bash 
