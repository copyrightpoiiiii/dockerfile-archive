# -*- mode: dockerfile -*-
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
# Dockerfile for Ubuntu based builds.
#
# See docker-compose.yml for supported BASE_IMAGE ARGs and targets.

####################################################################################################
# The Dockerfile uses a dynamic BASE_IMAGE (for example ubuntu:18.04
# nvidia/cuda:10.2-cudnn7-devel-ubuntu18.04 etc).
# On top of BASE_IMAGE we install all dependencies shared by all MXNet build
# environments into a "base" target. At the end of this file, we can specialize
# "base" for specific usecases. The target built by docker can be selected via
# "--target" option or docker-compose.yml
####################################################################################################
ARG BASE_IMAGE
FROM $BASE_IMAGE AS base

WORKDIR /work/deps

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y wget software-properties-common && \
    wget -qO - http://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
    wget -qO - wget https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB | apt-key add - && \
    apt-add-repository "deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial-10 main" &&  \
    apt-add-repository "deb https://apt.repos.intel.com/mkl all main" &&  \
    apt-get update && \
    apt-get install -y \
        ## Utilities
        curl \
        unzip \
        pandoc \
        ## Development tools
        build-essential \
        ninja-build \
        git \
        protobuf-compiler \
        libprotobuf-dev \
        clang-6.0 \
        clang-tidy-6.0 \
        python-yaml \
        clang-10 \
        g++ \
        g++-8 \
        intel-mkl-2020.0-088 \
        ## Dependencies
        libgomp1 \
        libturbojpeg0-dev \
        libopenblas-dev \
        libcurl4-openssl-dev \
        libatlas-base-dev \
        libzmq3-dev \
        liblapack-dev \
        libopencv-dev \
        # Caffe
        caffe-cpu \
        libcaffe-cpu-dev \
        # BytePS
        numactl \
        libnuma-dev \
        ## Frontend languages
        # Python
        python3 \
        python3-pip \
        python3-nose \
        python3-nose-timer \
        # Scala
        openjdk-8-jdk \
        openjdk-8-jre \
        maven \
        scala \
        # Clojure
        clojure \
        leiningen \
        # R
        r-base-core \
        r-cran-devtools \
        libcairo2-dev \
        libxml2-dev \
        ## Documentation
        doxygen \
        pandoc \
        ## Build-dependencies for ccache 3.7.9
        gperf \
        libb2-dev \
        libzstd-dev && \
    rm -rf /var/lib/apt/lists/*

# ccache 3.7.9 has fixes for caching nvcc outputs
RUN cd /usr/local/src && \
    git clone --recursive https://github.com/ccache/ccache.git && \
    cd ccache && \
    git checkout v3.7.9 && \
    ./autogen.sh && \
    ./configure --disable-man && \
    make -j$(nproc) && \
    make install && \
    cd /usr/local/src && \
    rm -rf ccache

# Python & cmake
COPY install/requirements /work/
RUN python3 -m pip install cmake==3.16.6 && \
    python3 -m pip install -r /work/requirements

# Only OpenJDK 8 supported at this time..
RUN update-java-alternatives -s java-1.8.0-openjdk-amd64

# julia not available on 18.04
COPY install/ubuntu_julia.sh /work/
RUN /work/ubuntu_julia.sh

# PDL::CCS missing on 18.04
COPY install/ubuntu_perl.sh /work/
RUN /work/ubuntu_perl.sh

# MXNetJS nightly needs emscripten for wasm
COPY install/ubuntu_emscripten.sh /work/
RUN /work/ubuntu_emscripten.sh

ARG USER_ID=0
COPY install/docker_filepermissions.sh /work/
RUN /work/docker_filepermissions.sh

ENV PYTHONPATH=./python/
WORKDIR /work/mxnet

COPY runtime_functions.sh /work/

####################################################################################################
# Specialize base image to install more gpu specific dependencies.
# The target built by docker can be selected via "--target" option or docker-compose.yml
####################################################################################################
FROM base as gpu
# Install Thrust 1.9.8 to be shipped with Cuda 11.
# Fixes https://github.com/thrust/thrust/issues/1072 for Clang 10
# This file can be deleted when using Cuda 11 on CI
RUN cd /usr/local && \
    git clone https://github.com/thrust/thrust.git && \
    cd thrust && \
    git checkout 1.9.8


FROM gpu as gpuwithcudaruntimelibs
# Special case because the CPP-Package requires the CUDA runtime libs
# and not only stubs (which are provided by the base image)
# This prevents usage of this image for actual GPU tests with Docker.
# This is a bug in CPP-Package and should be fixed.
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt install -y  --no-install-recommends \
        cuda-10-1 && \
    rm -rf /var/lib/apt/lists/*
