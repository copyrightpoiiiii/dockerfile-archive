FROM bunbunbunbun/bun-base:latest as lolhtml

RUN install_packages build-essential && curl https://sh.rustup.rs -sSf | sh -s -- -y

ARG DEBIAN_FRONTEND=noninteractive
ARG GITHUB_WORKSPACE=/build
ARG ZIG_PATH=${GITHUB_WORKSPACE}/zig
# Directory extracts to "bun-webkit"
ARG WEBKIT_DIR=${GITHUB_WORKSPACE}/bun-webkit 
ARG BUN_RELEASE_DIR=${GITHUB_WORKSPACE}/bun-release
ARG BUN_DEPS_OUT_DIR=${GITHUB_WORKSPACE}/bun-deps
ARG BUN_DIR=${GITHUB_WORKSPACE}/bun

COPY Makefile ${BUN_DIR}/Makefile
COPY src/deps/lol-html ${BUN_DIR}/src/deps/lol-html

RUN export PATH=$PATH:$HOME/.cargo/bin && export CC=$(which clang-13) && cd ${BUN_DIR} && \
    make lolhtml && rm -rf src/deps/lol-html Makefile

FROM bunbunbunbun/bun-base:latest as mimalloc

ARG DEBIAN_FRONTEND=noninteractive
ARG GITHUB_WORKSPACE=/build
ARG ZIG_PATH=${GITHUB_WORKSPACE}/zig
# Directory extracts to "bun-webkit"
ARG WEBKIT_DIR=${GITHUB_WORKSPACE}/bun-webkit 
ARG BUN_RELEASE_DIR=${GITHUB_WORKSPACE}/bun-release
ARG BUN_DEPS_OUT_DIR=${GITHUB_WORKSPACE}/bun-deps
ARG BUN_DIR=${GITHUB_WORKSPACE}/bun

COPY Makefile ${BUN_DIR}/Makefile
COPY src/deps/mimalloc ${BUN_DIR}/src/deps/mimalloc

RUN cd ${BUN_DIR} && \
    make mimalloc && rm -rf src/deps/mimalloc Makefile

FROM bunbunbunbun/bun-base:latest as zlib

ARG DEBIAN_FRONTEND=noninteractive
ARG GITHUB_WORKSPACE=/build
ARG ZIG_PATH=${GITHUB_WORKSPACE}/zig
# Directory extracts to "bun-webkit"
ARG WEBKIT_DIR=${GITHUB_WORKSPACE}/bun-webkit 
ARG BUN_RELEASE_DIR=${GITHUB_WORKSPACE}/bun-release
ARG BUN_DEPS_OUT_DIR=${GITHUB_WORKSPACE}/bun-deps
ARG BUN_DIR=${GITHUB_WORKSPACE}/bun

COPY Makefile ${BUN_DIR}/Makefile
COPY src/deps/zlib ${BUN_DIR}/src/deps/zlib

WORKDIR $BUN_DIR

RUN cd $BUN_DIR && \
    make zlib && rm -rf src/deps/zlib Makefile

FROM bunbunbunbun/bun-base:latest as libarchive

ARG DEBIAN_FRONTEND=noninteractive
ARG GITHUB_WORKSPACE=/build
ARG ZIG_PATH=${GITHUB_WORKSPACE}/zig
# Directory extracts to "bun-webkit"
ARG WEBKIT_DIR=${GITHUB_WORKSPACE}/bun-webkit 
ARG BUN_RELEASE_DIR=${GITHUB_WORKSPACE}/bun-release
ARG BUN_DEPS_OUT_DIR=${GITHUB_WORKSPACE}/bun-deps
ARG BUN_DIR=${GITHUB_WORKSPACE}/bun

COPY Makefile ${BUN_DIR}/Makefile
COPY src/deps/libarchive ${BUN_DIR}/src/deps/libarchive

WORKDIR $BUN_DIR

RUN cd $BUN_DIR && install_packages autoconf automake libtool pkg-config  && \ 
    make libarchive && rm -rf src/deps/libarchive Makefile

FROM bunbunbunbun/bun-base:latest as tinycc

ARG DEBIAN_FRONTEND=noninteractive
ARG GITHUB_WORKSPACE=/build
ARG ZIG_PATH=${GITHUB_WORKSPACE}/zig
# Directory extracts to "bun-webkit"
ARG WEBKIT_DIR=${GITHUB_WORKSPACE}/bun-webkit 
ARG BUN_RELEASE_DIR=${GITHUB_WORKSPACE}/bun-release
ARG BUN_DEPS_OUT_DIR=${GITHUB_WORKSPACE}/bun-deps
ARG BUN_DIR=${GITHUB_WORKSPACE}/bun

COPY Makefile ${BUN_DIR}/Makefile
COPY src/deps/tinycc ${BUN_DIR}/src/deps/tinycc

WORKDIR $BUN_DIR

RUN install_packages libtcc-dev && cp /usr/lib/$(uname -m)-linux-gnu/libtcc.a ${BUN_DEPS_OUT_DIR}

FROM bunbunbunbun/bun-base:latest as libbacktrace

ARG DEBIAN_FRONTEND=noninteractive
ARG GITHUB_WORKSPACE=/build
ARG ZIG_PATH=${GITHUB_WORKSPACE}/zig
# Directory extracts to "bun-webkit"
ARG WEBKIT_DIR=${GITHUB_WORKSPACE}/bun-webkit 
ARG BUN_RELEASE_DIR=${GITHUB_WORKSPACE}/bun-release
ARG BUN_DEPS_OUT_DIR=${GITHUB_WORKSPACE}/bun-deps
ARG BUN_DIR=${GITHUB_WORKSPACE}/bun

COPY Makefile ${BUN_DIR}/Makefile
COPY src/deps/libbacktrace ${BUN_DIR}/src/deps/libbacktrace

WORKDIR $BUN_DIR

RUN cd $BUN_DIR && \
    make libbacktrace && rm -rf src/deps/libbacktrace Makefile

FROM bunbunbunbun/bun-base:latest as boringssl

ARG DEBIAN_FRONTEND=noninteractive
ARG GITHUB_WORKSPACE=/build
ARG ZIG_PATH=${GITHUB_WORKSPACE}/zig
# Directory extracts to "bun-webkit"
ARG WEBKIT_DIR=${GITHUB_WORKSPACE}/bun-webkit 
ARG BUN_RELEASE_DIR=${GITHUB_WORKSPACE}/bun-release
ARG BUN_DEPS_OUT_DIR=${GITHUB_WORKSPACE}/bun-deps
ARG BUN_DIR=${GITHUB_WORKSPACE}/bun

COPY Makefile ${BUN_DIR}/Makefile
COPY src/deps/boringssl ${BUN_DIR}/src/deps/boringssl

WORKDIR $BUN_DIR

RUN install_packages golang && make boringssl && rm -rf src/deps/boringssl Makefile

FROM bunbunbunbun/bun-base:latest as base64

ARG DEBIAN_FRONTEND=noninteractive
ARG GITHUB_WORKSPACE=/build
ARG ZIG_PATH=${GITHUB_WORKSPACE}/zig
# Directory extracts to "bun-webkit"
ARG WEBKIT_DIR=${GITHUB_WORKSPACE}/bun-webkit 
ARG BUN_RELEASE_DIR=${GITHUB_WORKSPACE}/bun-release
ARG BUN_DEPS_OUT_DIR=${GITHUB_WORKSPACE}/bun-deps
ARG BUN_DIR=${GITHUB_WORKSPACE}/bun

COPY Makefile ${BUN_DIR}/Makefile
COPY src/base64 ${BUN_DIR}/src/base64

WORKDIR $BUN_DIR

RUN make base64 && rm -rf src/base64 Makefile

FROM bunbunbunbun/bun-base:latest as uws

ARG DEBIAN_FRONTEND=noninteractive
ARG GITHUB_WORKSPACE=/build
ARG ZIG_PATH=${GITHUB_WORKSPACE}/zig
# Directory extracts to "bun-webkit"
ARG WEBKIT_DIR=${GITHUB_WORKSPACE}/bun-webkit 
ARG BUN_RELEASE_DIR=${GITHUB_WORKSPACE}/bun-release
ARG BUN_DEPS_OUT_DIR=${GITHUB_WORKSPACE}/bun-deps
ARG BUN_DIR=${GITHUB_WORKSPACE}/bun

COPY Makefile ${BUN_DIR}/Makefile
COPY src/deps/uws ${BUN_DIR}/src/deps/uws
COPY src/deps/zlib ${BUN_DIR}/src/deps/zlib
COPY src/deps/boringssl/include ${BUN_DIR}/src/deps/boringssl/include
COPY src/deps/libuwsockets.cpp ${BUN_DIR}/src/deps/libuwsockets.cpp
COPY src/deps/_libusockets.h ${BUN_DIR}/src/deps/_libusockets.h

WORKDIR $BUN_DIR

RUN cd $BUN_DIR && \
    make uws && rm -rf src/deps/uws Makefile

FROM bunbunbunbun/bun-base:latest as picohttp

ARG DEBIAN_FRONTEND=noninteractive
ARG GITHUB_WORKSPACE=/build
ARG ZIG_PATH=${GITHUB_WORKSPACE}/zig
# Directory extracts to "bun-webkit"
ARG WEBKIT_DIR=${GITHUB_WORKSPACE}/bun-webkit 
ARG BUN_RELEASE_DIR=${GITHUB_WORKSPACE}/bun-release
ARG BUN_DEPS_OUT_DIR=${GITHUB_WORKSPACE}/bun-deps
ARG BUN_DIR=${GITHUB_WORKSPACE}/bun

COPY Makefile ${BUN_DIR}/Makefile
COPY src/deps/picohttpparser ${BUN_DIR}/src/deps/picohttpparser
COPY src/deps/*.c ${BUN_DIR}/src/deps/
COPY src/deps/*.h ${BUN_DIR}/src/deps/

WORKDIR $BUN_DIR

RUN cd $BUN_DIR && \
    make picohttp


FROM bunbunbunbun/bun-base-with-zig-and-webkit:latest as identifier_cache

ARG DEBIAN_FRONTEND=noninteractive
ARG GITHUB_WORKSPACE=/build
ARG ZIG_PATH=${GITHUB_WORKSPACE}/zig
# Directory extracts to "bun-webkit"
ARG WEBKIT_DIR=${GITHUB_WORKSPACE}/bun-webkit 
ARG BUN_RELEASE_DIR=${GITHUB_WORKSPACE}/bun-release
ARG BUN_DEPS_OUT_DIR=${GITHUB_WORKSPACE}/bun-deps
ARG BUN_DIR=${GITHUB_WORKSPACE}/bun

WORKDIR $BUN_DIR

COPY Makefile ${BUN_DIR}/Makefile
COPY src/js_lexer/identifier_data.zig ${BUN_DIR}/src/js_lexer/identifier_data.zig
COPY src/js_lexer/identifier_cache.zig ${BUN_DIR}/src/js_lexer/identifier_cache.zig

RUN cd $BUN_DIR && \
    make identifier-cache && rm -rf zig-cache Makefile

FROM bunbunbunbun/bun-base-with-zig-and-webkit:latest as node_fallbacks

ARG DEBIAN_FRONTEND=noninteractive
ARG GITHUB_WORKSPACE=/build
ARG ZIG_PATH=${GITHUB_WORKSPACE}/zig
# Directory extracts to "bun-webkit"
ARG WEBKIT_DIR=${GITHUB_WORKSPACE}/bun-webkit 
ARG BUN_RELEASE_DIR=${GITHUB_WORKSPACE}/bun-release
ARG BUN_DEPS_OUT_DIR=${GITHUB_WORKSPACE}/bun-deps
ARG BUN_DIR=${GITHUB_WORKSPACE}/bun

WORKDIR $BUN_DIR


COPY Makefile ${BUN_DIR}/Makefile
COPY src/node-fallbacks ${BUN_DIR}/src/node-fallbacks
RUN cd $BUN_DIR && \
    make node-fallbacks && rm -rf src/node-fallbacks/node_modules Makefile

FROM bunbunbunbun/bun-base-with-zig-and-webkit:latest as prepare_release

ARG DEBIAN_FRONTEND=noninteractive
ARG GITHUB_WORKSPACE=/build
ARG ZIG_PATH=${GITHUB_WORKSPACE}/zig
# Directory extracts to "bun-webkit"
ARG WEBKIT_DIR=${GITHUB_WORKSPACE}/bun-webkit 
ARG BUN_RELEASE_DIR=${GITHUB_WORKSPACE}/bun-release
ARG BUN_DEPS_OUT_DIR=${GITHUB_WORKSPACE}/bun-deps
ARG BUN_DIR=${GITHUB_WORKSPACE}/bun


WORKDIR $BUN_DIR

COPY ./src ${BUN_DIR}/src
COPY ./build.zig ${BUN_DIR}/build.zig
COPY ./completions ${BUN_DIR}/completions
COPY ./packages ${BUN_DIR}/packages
COPY ./build-id ${BUN_DIR}/build-id
COPY ./package.json ${BUN_DIR}/package.json
COPY ./misctools ${BUN_DIR}/misctools
COPY Makefile ${BUN_DIR}/Makefile


FROM prepare_release as compile_release_obj

ARG DEBIAN_FRONTEND=noninteractive
ARG GITHUB_WORKSPACE=/build
ARG ZIG_PATH=${GITHUB_WORKSPACE}/zig
# Directory extracts to "bun-webkit"
ARG WEBKIT_DIR=${GITHUB_WORKSPACE}/bun-webkit 
ARG BUN_RELEASE_DIR=${GITHUB_WORKSPACE}/bun-release
ARG BUN_DEPS_OUT_DIR=${GITHUB_WORKSPACE}/bun-deps
ARG BUN_DIR=${GITHUB_WORKSPACE}/bun

COPY Makefile ${BUN_DIR}/Makefile

WORKDIR $BUN_DIR

ENV JSC_BASE_DIR=${WEBKIT_DIR}
ENV LIB_ICU_PATH=${WEBKIT_DIR}/lib
ARG TRIPLET=x86_64-linux-gnu

COPY --from=identifier_cache ${BUN_DIR}/src/js_lexer/*.blob ${BUN_DIR}/src/js_lexer/
COPY --from=node_fallbacks ${BUN_DIR}/src/node-fallbacks/out ${BUN_DIR}/src/node-fallbacks/out

RUN cd $BUN_DIR && mkdir -p src/bun.js/bindings-obj &&  rm -rf $HOME/.cache zig-cache && make prerelease && \
    mkdir -p $BUN_RELEASE_DIR && \
    $ZIG_PATH/zig build obj -Drelease-fast -Dtarget=${TRIPLET} && \
    make bun-release-copy-obj

FROM scratch as build_release_obj

COPY --from=compile_release_obj /tmp/*.o /

FROM prepare_release as compile_cpp

ARG DEBIAN_FRONTEND=noninteractive
ARG GITHUB_WORKSPACE=/build
ARG ZIG_PATH=${GITHUB_WORKSPACE}/zig
# Directory extracts to "bun-webkit"
ARG WEBKIT_DIR=${GITHUB_WORKSPACE}/bun-webkit 
ARG BUN_RELEASE_DIR=${GITHUB_WORKSPACE}/bun-release
ARG BUN_DEPS_OUT_DIR=${GITHUB_WORKSPACE}/bun-deps
ARG BUN_DIR=${GITHUB_WORKSPACE}/bun

COPY Makefile ${BUN_DIR}/Makefile

WORKDIR $BUN_DIR

ENV JSC_BASE_DIR=${WEBKIT_DIR}
ENV LIB_ICU_PATH=${WEBKIT_DIR}/lib

COPY --from=lolhtml ${BUN_DEPS_OUT_DIR}/*.a ${BUN_DEPS_OUT_DIR}/
COPY --from=mimalloc ${BUN_DEPS_OUT_DIR}/*.o ${BUN_DEPS_OUT_DIR}/
COPY --from=libarchive ${BUN_DEPS_OUT_DIR}/*.a ${BUN_DEPS_OUT_DIR}/
COPY --from=picohttp ${BUN_DEPS_OUT_DIR}/*.o ${BUN_DEPS_OUT_DIR}/
COPY --from=boringssl ${BUN_DEPS_OUT_DIR}/*.a ${BUN_DEPS_OUT_DIR}/
COPY --from=uws ${BUN_DEPS_OUT_DIR}/*.a ${BUN_DEPS_OUT_DIR}/
COPY --from=uws ${BUN_DEPS_OUT_DIR}/*.o ${BUN_DEPS_OUT_DIR}/
COPY --from=libbacktrace ${BUN_DEPS_OUT_DIR}/*.a ${BUN_DEPS_OUT_DIR}/
COPY --from=zlib ${BUN_DEPS_OUT_DIR}/*.a ${BUN_DEPS_OUT_DIR}/
COPY --from=tinycc ${BUN_DEPS_OUT_DIR}/*.a ${BUN_DEPS_OUT_DIR}/
COPY --from=base64 ${BUN_DEPS_OUT_DIR}/*.a ${BUN_DEPS_OUT_DIR}/

RUN cd $BUN_DIR && mkdir -p src/bun.js/bindings-obj &&  rm -rf $HOME/.cache zig-cache && mkdir -p $BUN_RELEASE_DIR && \
    make jsc-bindings-mac -j10 && mv src/bun.js/bindings-obj/* /tmp

FROM prepare_release as sqlite

ARG DEBIAN_FRONTEND=noninteractive
ARG GITHUB_WORKSPACE=/build
ARG ZIG_PATH=${GITHUB_WORKSPACE}/zig
# Directory extracts to "bun-webkit"
ARG WEBKIT_DIR=${GITHUB_WORKSPACE}/bun-webkit 
ARG BUN_RELEASE_DIR=${GITHUB_WORKSPACE}/bun-release
ARG BUN_DEPS_OUT_DIR=${GITHUB_WORKSPACE}/bun-deps
ARG BUN_DIR=${GITHUB_WORKSPACE}/bun

COPY Makefile ${BUN_DIR}/Makefile

WORKDIR $BUN_DIR

ENV JSC_BASE_DIR=${WEBKIT_DIR}
ENV LIB_ICU_PATH=${WEBKIT_DIR}/lib

RUN cd $BUN_DIR && make sqlite

FROM scratch as build_release_cpp

COPY --from=compile_cpp /tmp/*.o /

FROM prepare_release as build_release

ARG DEBIAN_FRONTEND=noninteractive
ARG GITHUB_WORKSPACE=/build
ARG ZIG_PATH=${GITHUB_WORKSPACE}/zig
# Directory extracts to "bun-webkit"
ARG WEBKIT_DIR=${GITHUB_WORKSPACE}/bun-webkit 
ARG BUN_RELEASE_DIR=${GITHUB_WORKSPACE}/bun-release
ARG BUN_DEPS_OUT_DIR=${GITHUB_WORKSPACE}/bun-deps
ARG BUN_DIR=${GITHUB_WORKSPACE}/bun

COPY Makefile ${BUN_DIR}/Makefile

WORKDIR $BUN_DIR

ENV JSC_BASE_DIR=${WEBKIT_DIR}
ENV LIB_ICU_PATH=${WEBKIT_DIR}/lib

COPY --from=lolhtml ${BUN_DEPS_OUT_DIR}/*.a ${BUN_DEPS_OUT_DIR}/
COPY --from=mimalloc ${BUN_DEPS_OUT_DIR}/*.o ${BUN_DEPS_OUT_DIR}/
COPY --from=libarchive ${BUN_DEPS_OUT_DIR}/*.a ${BUN_DEPS_OUT_DIR}/
COPY --from=picohttp ${BUN_DEPS_OUT_DIR}/*.o ${BUN_DEPS_OUT_DIR}/
COPY --from=boringssl ${BUN_DEPS_OUT_DIR}/*.a ${BUN_DEPS_OUT_DIR}/
COPY --from=uws ${BUN_DEPS_OUT_DIR}/*.a ${BUN_DEPS_OUT_DIR}/
COPY --from=uws ${BUN_DEPS_OUT_DIR}/*.o ${BUN_DEPS_OUT_DIR}/
COPY --from=libbacktrace ${BUN_DEPS_OUT_DIR}/*.a ${BUN_DEPS_OUT_DIR}/
COPY --from=zlib ${BUN_DEPS_OUT_DIR}/*.a ${BUN_DEPS_OUT_DIR}/
COPY --from=tinycc ${BUN_DEPS_OUT_DIR}/*.a ${BUN_DEPS_OUT_DIR}/
COPY --from=base64 ${BUN_DEPS_OUT_DIR}/*.a ${BUN_DEPS_OUT_DIR}/
COPY --from=sqlite ${BUN_DEPS_OUT_DIR}/*.o  ${BUN_DEPS_OUT_DIR}/
COPY --from=build_release_obj /*.o /tmp
COPY --from=build_release_cpp /*.o ${BUN_DIR}/src/bun.js/bindings-obj/

RUN cd $BUN_DIR && mkdir -p ${BUN_RELEASE_DIR} && make bun-relink copy-to-bun-release-dir && \
    rm -rf $HOME/.cache zig-cache misctools package.json build-id completions build.zig $(BUN_DIR)/packages

FROM prepare_release as build_unit

ARG DEBIAN_FRONTEND=noninteractive
ARG GITHUB_WORKSPACE=/build
ARG ZIG_PATH=${GITHUB_WORKSPACE}/zig
# Directory extracts to "bun-webkit"
ARG WEBKIT_DIR=${GITHUB_WORKSPACE}/bun-webkit 
ARG BUN_RELEASE_DIR=${GITHUB_WORKSPACE}/bun-release
ARG BUN_DEPS_OUT_DIR=${GITHUB_WORKSPACE}/bun-deps
ARG BUN_DIR=${GITHUB_WORKSPACE}/bun

WORKDIR $BUN_DIR

ENV PATH "$ZIG_PATH:$PATH"
ENV LIB_ICU_PATH "${WEBKIT_DIR}/lib"

CMD make jsc-bindings-headers \
    api \
    analytics \
    bun_error \
    fallback_decoder \
    jsc-bindings-mac -j10 && \
    make \
    run-all-unit-tests

FROM alpine:latest as release_with_debug_info

ARG DEBIAN_FRONTEND=noninteractive
ARG GITHUB_WORKSPACE=/build
ARG ZIG_PATH=${GITHUB_WORKSPACE}/zig
ARG WEBKIT_DIR=${GITHUB_WORKSPACE}/bun-webkit 
ARG BUN_RELEASE_DIR=${GITHUB_WORKSPACE}/bun-release
ARG BUN_DEPS_OUT_DIR=${GITHUB_WORKSPACE}/bun-deps
ARG BUN_DIR=${GITHUB_WORKSPACE}/bun

COPY .devcontainer/limits.conf /etc/security/limits.conf

ENV BUN_INSTALL /opt/bun
ENV PATH "/opt/bun/bin:$PATH"
ARG BUILDARCH=amd64
LABEL org.opencontainers.image.title="bun ${BUILDARCH} (glibc)"
LABEL org.opencontainers.image.source=https://github.com/jarred-sumner/bun
COPY --from=build_release ${BUN_RELEASE_DIR}/bun /opt/bun/bin/bun
COPY --from=build_release ${BUN_RELEASE_DIR}/bun-profile /opt/bun/bin/bun-profile

WORKDIR /opt/bun

ENTRYPOINT [ "/opt/bun/bin/bun" ]

FROM alpine:latest as release 

ARG DEBIAN_FRONTEND=noninteractive
ARG GITHUB_WORKSPACE=/build
ARG ZIG_PATH=${GITHUB_WORKSPACE}/zig
# Directory extracts to "bun-webkit"
ARG WEBKIT_DIR=${GITHUB_WORKSPACE}/bun-webkit 
ARG BUN_RELEASE_DIR=${GITHUB_WORKSPACE}/bun-release
ARG BUN_DEPS_OUT_DIR=${GITHUB_WORKSPACE}/bun-deps
ARG BUN_DIR=${GITHUB_WORKSPACE}/bun

COPY .devcontainer/limits.conf /etc/security/limits.conf

ENV BUN_INSTALL /opt/bun
ENV PATH "/opt/bun/bin:$PATH"
ARG BUILDARCH=amd64
LABEL org.opencontainers.image.title="bun ${BUILDARCH} (glibc)"
LABEL org.opencontainers.image.source=https://github.com/jarred-sumner/bun
COPY --from=build_release ${BUN_RELEASE_DIR}/bun /opt/bun
WORKDIR /opt/bun

ENTRYPOINT [ "/opt/bun/bin/bun" ]


# FROM bunbunbunbun/bun-test-base as test_base

# ARG DEBIAN_FRONTEND=noninteractive
# ARG GITHUB_WORKSPACE=/build
# ARG ZIG_PATH=${GITHUB_WORKSPACE}/zig
# # Directory extracts to "bun-webkit"
# ARG WEBKIT_DIR=${GITHUB_WORKSPACE}/bun-webkit 
# ARG BUN_RELEASE_DIR=${GITHUB_WORKSPACE}/bun-release
# ARG BUN_DEPS_OUT_DIR=${GITHUB_WORKSPACE}/bun-deps
# ARG BUN_DIR=${GITHUB_WORKSPACE}/bun

# ARG BUILDARCH=amd64
# RUN groupadd -r chromium && useradd   -d  ${BUN_DIR} -M -r -g chromium -G audio,video chromium \
#     && mkdir -p /home/chromium/Downloads && chown -R chromium:chromium /home/chromium

# USER chromium
# WORKDIR $BUN_DIR

# ENV NPM_CLIENT bun
# ENV PATH "${BUN_DIR}/packages/bun-linux-x64:${BUN_DIR}/packages/bun-linux-aarch64:$PATH"
# ENV CI 1
# ENV BROWSER_EXECUTABLE /usr/bin/chromium

# COPY ./test ${BUN_DIR}/test
# COPY Makefile ${BUN_DIR}/Makefile
# COPY package.json ${BUN_DIR}/package.json
# COPY .docker/run-test.sh ${BUN_DIR}/run-test.sh
# COPY ./bun.lockb ${BUN_DIR}/bun.lockb   

# # # We don't want to worry about architecture differences in this image
# COPY --from=release /opt/bun/bin/bun ${BUN_DIR}/packages/bun-linux-aarch64/bun
# COPY --from=release /opt/bun/bin/bun ${BUN_DIR}/packages/bun-linux-x64/bun

# USER root
# RUN chgrp -R chromium ${BUN_DIR} && chmod g+rwx ${BUN_DIR} && chown -R chromium:chromium ${BUN_DIR}
# USER chromium

# CMD [ "bash", "run-test.sh" ]

# FROM release
