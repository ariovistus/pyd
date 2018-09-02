from fedora:28

ENV \
    COMPILER=dmd \
    COMPILER_VERSION=2.082.0

run dnf install -y python-devel python-nose python-numpy
run dnf install -y python3-devel python3-nose python3-numpy
run dnf install -y ldc gcc xz
RUN curl -fsS -o /tmp/install.sh https://dlang.org/install.sh \
    && bash /tmp/install.sh -p /dlang install "${COMPILER}-${COMPILER_VERSION}" \
    && rm /tmp/install.sh \
    && rm -rf /dlang/${COMPILER}-*/linux/bin32 \
    && rm -rf /dlang/${COMPILER}-*/linux/lib32 \
    && rm -rf /dlang/${COMPILER}-*/html \
    && rm -rf /dlang/dub-1.0.0/dub.tar.gz

ENV \
    PATH=/dlang/dub:/dlang/${COMPILER}-${COMPILER_VERSION}/linux/bin64:${PATH} \
    LD_LIBRARY_PATH=/dlang/${COMPILER}-${COMPILER_VERSION}/linux/lib64 \
    LIBRARY_PATH=/dlang/${COMPILER}-${COMPILER_VERSION}/linux/lib64 \
    PS1="(${COMPILER}-${COMPILER_VERSION}) \\u@\\h:\\w\$"
workdir /src
