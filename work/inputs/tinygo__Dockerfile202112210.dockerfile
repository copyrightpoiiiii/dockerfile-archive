# tinygo-llvm stage obtains the llvm source for TinyGo
FROM golang:1.17 AS tinygo-llvm

RUN apt-get update && \
    apt-get install -y apt-utils make cmake clang-11 binutils-avr gcc-avr avr-libc ninja-build

COPY ./Makefile /tinygo/Makefile

RUN cd /tinygo/ && \
    make llvm-source

# tinygo-llvm-build stage build the custom llvm with xtensa support
FROM tinygo-llvm AS tinygo-llvm-build

RUN cd /tinygo/ && \
    make llvm-build

# tinygo-compiler stage builds the compiler itself
FROM tinygo-llvm-build AS tinygo-compiler

COPY . /tinygo

# remove submodules directories and re-init them to fix any hard-coded paths
# after copying the tinygo directory in the previous step.
RUN cd /tinygo/ && \
    rm -rf ./lib/* && \
    git submodule sync && \
    git submodule update --init --recursive --force

RUN cd /tinygo/ && \
    make

# tinygo-tools stage installs the needed dependencies to compile TinyGo programs for all platforms.
FROM tinygo-compiler AS tinygo-tools

RUN cd /tinygo/ && \
    make wasi-libc binaryen && \
    make gen-device -j4 && \
    cp build/* $GOPATH/bin/

CMD ["tinygo"]
