from python:3.7-stretch

ENV \
 	COMPILER=gdc \
	COMPILER_VERSION=5.2.0

RUN apt-get update && apt-get install -y curl libcurl3 build-essential \
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
  PATH=/dlang/${COMPILER}-${COMPILER_VERSION}/bin:${PATH} \
  LD_LIBRARY_PATH=/dlang/${COMPILER}-${COMPILER_VERSION}/lib \
  LIBRARY_PATH=/dlang/${COMPILER}-${COMPILER_VERSION}/lib \
  PS1="(${COMPILER}-${COMPILER_VERSION}) \\u@\\h:\\w\$"

RUN cd /tmp \
 && echo 'void main() {import std.stdio; stdout.writeln("it works"); }' > test.d \
 && gdc test.d -otest \
 && ./test && rm test*

RUN pip3 install nose numpy
WORKDIR /src
