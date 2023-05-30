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
LABEL version="2"

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update; \
 apt-get -qqy install --no-install-recommends \
  build-essential \
  software-properties-common \
  ninja-build git wget \
  libbz2-dev zlib1g-dev git curl; \
    apt-get install -qy python-pip python-sphinx;

# Install cmake 3.14 (minimum requirement is cmake 3.10)
RUN wget https://github.com/Kitware/CMake/releases/download/v3.14.5/cmake-3.14.5-Linux-x86_64.sh; \
    chmod +x cmake-3.14.5-Linux-x86_64.sh; \
    ./cmake-3.14.5-Linux-x86_64.sh --skip-license --prefix="/usr"

FROM base AS libraries

# Boost
RUN git clone -b boost-1.69.0 https://github.com/boostorg/boost.git \
    /usr/src/boost; \
    cd /usr/src/boost; \
    git submodule update --init --recursive; \
    ./bootstrap.sh --with-toolset=clang --prefix=/usr; \
    ./b2 toolset=clang cxxflags="-stdlib=libc++" linkflags="-stdlib=libc++" headers; \
    ./b2 toolset=clang cxxflags="-stdlib=libc++" linkflags="-stdlib=libc++" \
        link=static variant=release runtime-link=static \
        system filesystem unit_test_framework program_options \
        install -j $(($(nproc)/2)); \
    rm -rf /usr/src/boost

# Z3
RUN git clone --depth 1 -b z3-4.8.7 https://github.com/Z3Prover/z3.git \
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
 git clone --branch="v0.4.0" --recurse-submodules https://github.com/ethereum/evmone.git; \
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
 git clone --branch="v0.3.0" --recurse-submodules https://github.com/ewasm/hera.git; \
 cd hera; \
 mkdir build; \
 cd build; \
 cmake -G Ninja -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX="/usr" ..; \
 ninja; \
 ninja install/strip; \
 rm -rf /usr/src/hera

FROM base
COPY --from=libraries /usr/lib /usr/lib
COPY --from=libraries /usr/bin /usr/bin
COPY --from=libraries /usr/include /usr/include