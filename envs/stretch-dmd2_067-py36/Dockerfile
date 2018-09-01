from python:3.6-stretch

ENV \
 	COMPILER=dmd \
	COMPILER_VERSION=2.067.1

RUN apt-get update && apt-get install -y curl libcurl3 build-essential unzip \
 && curl -fsS -o /tmp/install.sh https://dlang.org/install.sh \
 && bash /tmp/install.sh -p /dlang install "${COMPILER}-${COMPILER_VERSION}" \
 && rm /tmp/install.sh \
 && apt-get auto-remove -y curl build-essential \
 && apt-get install -y gcc \
 && rm -rf /var/cache/apt \
 && rm -rf /dlang/${COMPILER}-*/linux/bin32 \
 && rm -rf /dlang/${COMPILER}-*/linux/lib32 \
 && rm -rf /dlang/${COMPILER}-*/html \
 && rm -rf /dlang/dub-1.0.0/dub.tar.gz

ENV \
  PATH=/dlang/dub:/dlang/${COMPILER}-${COMPILER_VERSION}/linux/bin64:${PATH} \
  LD_LIBRARY_PATH=/dlang/${COMPILER}-${COMPILER_VERSION}/linux/lib64 \
  LIBRARY_PATH=/dlang/${COMPILER}-${COMPILER_VERSION}/linux/lib64 \
  PS1="(${COMPILER}-${COMPILER_VERSION}) \\u@\\h:\\w\$"

RUN cd /tmp \
 && echo 'void main() {import std.stdio; stdout.writeln("it works"); }' > test.d \
 && dmd test.d \
 && ./test && rm test*

RUN pip3 install nose numpy
WORKDIR /src
