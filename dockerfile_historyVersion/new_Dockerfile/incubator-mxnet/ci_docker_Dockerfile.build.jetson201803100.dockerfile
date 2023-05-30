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
# Dockerfile to build libmxnet.so, and a python wheel for the Jetson TX1/TX2
# This script assumes /work/mxnet exists and contains the mxnet code you wish to compile and
# that /work/build exists and is the target for your output.

FROM nvidia/cuda:8.0-cudnn6-devel as cudabuilder

FROM dockcross/linux-arm64

ENV ARCH aarch64
ENV NVCCFLAGS "-m64"
ENV CC /usr/bin/aarch64-linux-gnu-gcc
ENV CXX /usr/bin/aarch64-linux-gnu-g++
ENV FC /usr/bin/aarch64-linux-gnu-gfortran-4.9
ENV HOSTCC gcc

WORKDIR /work

# Build OpenBLAS
ADD https://api.github.com/repos/xianyi/OpenBLAS/git/refs/heads/master /tmp/openblas_version.json
RUN git clone https://github.com/xianyi/OpenBLAS.git && \
    cd OpenBLAS && \
    make -j$(nproc) TARGET=ARMV8 && \
    PREFIX=/usr make install

# Setup CUDA build env (including configuring and copying nvcc)
COPY --from=cudabuilder /usr/local/cuda /usr/local/cuda
ENV PATH $PATH:/usr/local/cuda/bin
ENV TARGET_ARCH aarch64
ENV TARGET_OS linux

# Install ARM depedencies based on Jetpack 3.1
RUN JETPACK_DOWNLOAD_PREFIX=http://developer.download.nvidia.com/devzone/devcenter/mobile/jetpack_l4t/013/linux-x64 && \
    ARM_CUDA_INSTALLER_PACKAGE=cuda-repo-l4t-8-0-local_8.0.84-1_arm64.deb && \
    ARM_CUDNN_INSTALLER_PACKAGE=libcudnn6_6.0.21-1+cuda8.0_arm64.deb && \
    ARM_CUDNN_DEV_INSTALLER_PACKAGE=libcudnn6-dev_6.0.21-1+cuda8.0_arm64.deb && \
    wget -nv $JETPACK_DOWNLOAD_PREFIX/$ARM_CUDA_INSTALLER_PACKAGE && \
    wget -nv $JETPACK_DOWNLOAD_PREFIX/$ARM_CUDNN_INSTALLER_PACKAGE && \
    wget -nv $JETPACK_DOWNLOAD_PREFIX/$ARM_CUDNN_DEV_INSTALLER_PACKAGE && \
    dpkg -i $ARM_CUDA_INSTALLER_PACKAGE && \
    dpkg -i $ARM_CUDNN_INSTALLER_PACKAGE && \
    dpkg -i $ARM_CUDNN_DEV_INSTALLER_PACKAGE && \
    apt update -y  && \
    apt install -y unzip cuda-cudart-cross-aarch64-8-0 cuda-cublas-cross-aarch64-8-0 \
    cuda-nvml-cross-aarch64-8-0 cuda-nvrtc-cross-aarch64-8-0 cuda-cufft-cross-aarch64-8-0 \
    cuda-curand-cross-aarch64-8-0 cuda-cusolver-cross-aarch64-8-0 cuda-cusparse-cross-aarch64-8-0 \
    cuda-misc-headers-cross-aarch64-8-0 cuda-npp-cross-aarch64-8-0 libcudnn6  && \
    cp /usr/local/cuda-8.0/targets/aarch64-linux/lib/*.so /usr/local/cuda/lib64/ && \
    cp /usr/local/cuda-8.0/targets/aarch64-linux/lib/stubs/*.so /usr/local/cuda/lib64/stubs/ && \
    cp -r /usr/local/cuda-8.0/targets/aarch64-linux/include/ /usr/local/cuda/include/ && \
    rm $ARM_CUDA_INSTALLER_PACKAGE $ARM_CUDNN_INSTALLER_PACKAGE $ARM_CUDNN_DEV_INSTALLER_PACKAGE

WORKDIR /work/mxnet

COPY runtime_functions.sh /work/
