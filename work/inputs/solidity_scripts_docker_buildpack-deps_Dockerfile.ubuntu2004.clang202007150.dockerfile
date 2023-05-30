# vim:syntax=dockerfile
#------------------------------------------------------------------------------
# Dockerfile for building and testing Solidity Compiler on CI
# Target: Ubuntu 19.04 (Disco Dingo) Clang variant
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
FROM buildpack-deps:focal AS base
LABEL version="0"

ARG DEBIAN_FRONTEND=noninteractive

RUN set -ex; \
 dist=$(grep DISTRIB_CODENAME /etc/lsb-release | cut -d= -f2); \
 echo "deb http://ppa.launchpad.net/ethereum/cpp-build-deps/ubuntu $dist main" >> /etc/apt/sources.list ; \
 apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1c52189c923f6ca9 ; \
 apt-get update; \
 apt-get install -qqy --no-install-recommends \
  build-essential \
  software-properties-common \
  cmake ninja-build \
  libboost-filesystem-dev libboost-test-dev libboost-system-dev \
  libboost-program-options-dev \
  clang \
  libz3-static-dev \
  ; \
 rm -rf /var/lib/apt/lists/*

FROM base AS libraries

ENV CC clang
ENV CXX clang++

# EVMONE
RUN set -ex; \
 cd /usr/src; \
 git clone --branch="v0.4.0" --recurse-submodules https://github.com/ethereum/evmone.git; \
 cd evmone; \
 mkdir build; \
 cd build; \
 cmake -G Ninja -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX="/usr" ..; \
 ninja; \
 ninja install/strip; \
 rm -rf /usr/src/evmone

FROM base
COPY --from=libraries /usr/lib /usr/lib
COPY --from=libraries /usr/bin /usr/bin
COPY --from=libraries /usr/include /usr/include
