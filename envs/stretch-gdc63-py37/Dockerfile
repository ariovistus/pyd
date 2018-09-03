from python:3.7-stretch

ENV \
 	COMPILER=gdc \
	COMPILER_VERSION=6.3.0

RUN apt-get update && apt-get install -y curl libcurl3 build-essential 

RUN curl -o dub.tar.gz https://code.dlang.org/files/dub-1.9.0-linux-x86_64.tar.gz && \
    tar -xf dub.tar.gz && \
    mv dub /bin && \
    rm -rf dub.tar.gz

RUN curl https://gdcproject.org/downloads/binaries/6.3.0/x86_64-linux-gnu/gdc-6.3.0+2.068.2.tar.xz -o gdc-6.3.0+2.068.2.tar.xz && \
    tar -xf gdc-6.3.0+2.068.2.tar.xz && \
    mv /x86_64-unknown-linux-gnu/include/c++/6.3.0/ /x86_64-unknown-linux-gnu/include/c++/6 && \
    cp -ax /x86_64-unknown-linux-gnu/lib64/* /x86_64-unknown-linux-gnu/lib && \
    cp x86_64-unknown-linux-gnu/* /usr -R  && \
    rm gdc-6.3.0+2.068.2.tar.xz && \
    rm x86_64-unknown-linux-gnu/ -rf

RUN pip3 install nose numpy

WORKDIR /src
