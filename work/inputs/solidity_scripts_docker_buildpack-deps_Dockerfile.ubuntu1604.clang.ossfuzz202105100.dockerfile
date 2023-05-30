# vim:syntax=dockerfile
#------------------------------------------------------------------------------
# Dockerfile for building and testing Solidity Compiler on CI
# Target: Ubuntu 16.04 (Xenial Xerus) ossfuzz Clang variant
# URL: https://hub.docker.com/r/ethereum/solidity-buildpack-deps
#
# This file is part of solidity.
#
# solidity is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# solidity is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with solidity.  If not, see <http://www.gnu.org/licenses/>
#
# (c) 2016-2019 solidity contributors.
#------------------------------------------------------------------------------
FROM gcr.io/oss-fuzz-base/base-clang as base
LABEL version="9"

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update; \
 apt-get -qqy install --no-install-recommends \
  build-essential \
  software-properties-common \
  ninja-build git wget \
  libbz2-dev zlib1g-dev git curl uuid-dev \
  pkg-config openjdk-8-jdk liblzma-dev unzip mlton m4; \
    apt-get install -qy python-pip python-sphinx;

# Install cmake 3.14 (minimum requirement is cmake 3.10)
RUN wget https://github.com/Kitware/CMake/releases/download/v3.14.5/cmake-3.14.5-Linux-x86_64.sh; \
    chmod +x cmake-3.14.5-Linux-x86_64.sh; \
    ./cmake-3.14.5-Linux-x86_64.sh --skip-license --prefix="/usr"

FROM base AS libraries

# Boost
RUN set -ex; \
    cd /usr/src; \
    wget -q 'https://boostorg.jfrog.io/artifactory/main/release/1.73.0/source/boost_1_73_0.tar.bz2' -O boost.tar.bz2; \
    test "$(sha256sum boost.tar.bz2)" = "4eb3b8d442b426dc35346235c8733b5ae35ba431690e38c6a8263dce9fcbb402  boost.tar.bz2"; \
    tar -xf boost.tar.bz2; \
    rm boost.tar.bz2; \
    cd boost_1_73_0; \
    CXXFLAGS="-stdlib=libc++ -pthread" LDFLAGS="-stdlib=libc++" ./bootstrap.sh --with-toolset=clang --prefix=/usr; \
    ./b2 toolset=clang cxxflags="-stdlib=libc++ -pthread" linkflags="-stdlib=libc++ -pthread" headers; \
    ./b2 toolset=clang cxxflags="-stdlib=libc++ -pthread" linkflags="-stdlib=libc++ -pthread" \
        link=static variant=release runtime-link=static \
        system filesystem unit_test_framework program_options \
        install -j $(($(nproc)/2)); \
    rm -rf /usr/src/boost_1_73_0

# Z3
RUN set -ex; \
    git clone --depth 1 -b z3-4.8.10 https://github.com/Z3Prover/z3.git \
    /usr/src/z3; \
    cd /usr/src/z3; \
    mkdir build; \
    cd build; \
    LDFLAGS=$CXXFLAGS cmake -DZ3_BUILD_LIBZ3_SHARED=OFF -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_BUILD_TYPE=Release ..; \
    make libz3 -j; \
    make install; \
    rm -rf /usr/src/z3

# OSSFUZZ: libprotobuf-mutator
RUN set -ex; \
 git clone https://github.com/google/libprotobuf-mutator.git \
     /usr/src/libprotobuf-mutator; \
 cd /usr/src/libprotobuf-mutator; \
 git checkout 3521f47a2828da9ace403e4ecc4aece1a84feb36; \
 mkdir build; \
 cd build; \
 cmake .. -GNinja -DLIB_PROTO_MUTATOR_DOWNLOAD_PROTOBUF=ON \
        -DLIB_PROTO_MUTATOR_TESTING=OFF -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="/usr"; \
 ninja; \
 cp -vpr external.protobuf/bin/* /usr/bin/; \
 cp -vpr external.protobuf/include/* /usr/include/; \
 cp -vpr external.protobuf/lib/* /usr/lib/; \
 ninja install/strip; \
 rm -rf /usr/src/libprotobuf-mutator

# EVMONE
RUN set -ex; \
 cd /usr/src; \
 git clone --branch="v0.7.0" --recurse-submodules https://github.com/ethereum/evmone.git; \
 cd evmone; \
 mkdir build; \
 cd build; \
 cmake -G Ninja -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX="/usr" ..; \
 ninja; \
 ninja install/strip; \
 rm -rf /usr/src/evmone

# HERA
RUN set -ex; \
 cd /usr/src; \
 git clone --branch="v0.3.2" --depth 1 --recurse-submodules https://github.com/ewasm/hera.git; \
 cd hera; \
 mkdir build; \
 cd build; \
 cmake -G Ninja -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX="/usr" ..; \
 ninja; \
 ninja install/strip; \
 rm -rf /usr/src/hera

# gmp
RUN set -ex; \
    # Replace system installed libgmp static library
    # with sanitized version. Do not perform apt
    # remove because it removes mlton as well that
    # we need for building libabicoder
    rm -f /usr/lib/x86_64-linux-gnu/libgmp.*; \
    rm -f /usr/include/x86_64-linux-gnu/gmp.h; \
    cd /usr/src; \
    wget -q 'https://gmplib.org/download/gmp/gmp-6.2.1.tar.xz' -O gmp.tar.xz; \
    test "$(sha256sum gmp.tar.xz)" = "fd4829912cddd12f84181c3451cc752be224643e87fac497b69edddadc49b4f2  gmp.tar.xz"; \
    tar -xf gmp.tar.xz; \
    cd gmp-6.2.1; \
    ./configure --prefix=/usr --enable-static=yes; \
    make -j; \
    make install; \
    rm -rf /usr/src/gmp-6.2.1; \
    rm -f /usr/src/gmp.tar.xz

# libabicoder
RUN set -ex; \
    cd /usr/src; \
    git clone https://github.com/ekpyron/Yul-Isabelle; \
    cd Yul-Isabelle; \
    cd libabicoder; \
    CXX=clang++ CXXFLAGS="-stdlib=libc++ -pthread" make; \
    cp libabicoder.a /usr/lib; \
    cp abicoder.hpp /usr/include; \
    rm -rf /usr/src/Yul-Isabelle

FROM base
COPY --from=libraries /usr/lib /usr/lib
COPY --from=libraries /usr/bin /usr/bin
COPY --from=libraries /usr/include /usr/include
