# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Dockerfile for installing the necessary dependencies for building Hadoop.
# See BUILDING.txt.

FROM ubuntu:focal

WORKDIR /root

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

#####
# Disable suggests/recommends
#####
RUN echo APT::Install-Recommends "0"\; > /etc/apt/apt.conf.d/10disableextras
RUN echo APT::Install-Suggests "0"\; >>  /etc/apt/apt.conf.d/10disableextras

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_TERSE true

# hadolint ignore=DL3008
RUN apt-get -q update \
    && apt-get -q install -y --no-install-recommends \
        ant \
        apt-utils \
        bats \
        build-essential \
        bzip2 \
        clang \
        cmake \
        curl \
        doxygen \
        findbugs \
        fuse \
        g++ \
        gcc \
        git \
        gnupg-agent \
        hugo \
        libbcprov-java \
        libbz2-dev \
        libcurl4-openssl-dev \
        libfuse-dev \
        libprotobuf-dev \
        libprotoc-dev \
        libsasl2-dev \
        libsnappy-dev \
        libssl-dev \
        libtool \
        libzstd-dev \
        locales \
        make \
        maven \
        nodejs \
        node-yarn \
        npm \
        openjdk-11-jdk \
        openjdk-8-jdk \
        pinentry-curses \
        pkg-config \
        python3 \
        python3-pip \
        python3-pkg-resources \
        python3-setuptools \
        python3-wheel \
        rsync \
        shellcheck \
        software-properties-common \
        sudo \
        valgrind \
        zlib1g-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

######
# Set env vars required to build Hadoop
######
ENV MAVEN_HOME /usr
# JAVA_HOME must be set in Maven >= 3.5.0 (MNG-6003)
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV FINDBUGS_HOME /usr

#######
# Install Boost 1.72 (1.71 ships with Focal)
#######
# hadolint ignore=DL3003
RUN mkdir -p /opt/boost-library \
    && curl -L https://sourceforge.net/projects/boost/files/boost/1.72.0/boost_1_72_0.tar.bz2/download > boost_1_72_0.tar.bz2 \
    && mv boost_1_72_0.tar.bz2 /opt/boost-library \
    && cd /opt/boost-library \
    && tar --bzip2 -xf boost_1_72_0.tar.bz2 \
    && cd /opt/boost-library/boost_1_72_0 \
    && ./bootstrap.sh --prefix=/usr/ \
    && ./b2 --without-python install \
    && cd /root \
    && rm -rf /opt/boost-library

######
# Install Google Protobuf 3.7.1 (3.6.1 ships with Focal)
######
# hadolint ignore=DL3003
RUN mkdir -p /opt/protobuf-src \
    && curl -L -s -S \
      https://github.com/protocolbuffers/protobuf/releases/download/v3.7.1/protobuf-java-3.7.1.tar.gz \
      -o /opt/protobuf.tar.gz \
    && tar xzf /opt/protobuf.tar.gz --strip-components 1 -C /opt/protobuf-src \
    && cd /opt/protobuf-src \
    && ./configure --prefix=/opt/protobuf \
    && make "-j$(nproc)" \
    && make install \
    && cd /root \
    && rm -rf /opt/protobuf-src
ENV PROTOBUF_HOME /opt/protobuf
ENV PATH "${PATH}:/opt/protobuf/bin"

####
# Install pylint and python-dateutil
####
RUN pip3 install pylint==2.6.0 python-dateutil==2.8.1

####
# Install bower
####
# hadolint ignore=DL3008
RUN npm install -g bower@1.8.8

###
# Install hadolint
####
RUN curl -L -s -S \
        https://github.com/hadolint/hadolint/releases/download/v1.11.1/hadolint-Linux-x86_64 \
        -o /bin/hadolint \
   && chmod a+rx /bin/hadolint \
   && shasum -a 512 /bin/hadolint | \
        awk '$1!="734e37c1f6619cbbd86b9b249e69c9af8ee1ea87a2b1ff71dccda412e9dac35e63425225a95d71572091a3f0a11e9a04c2fc25d9e91b840530c26af32b9891ca" {exit(1)}'

######
# Intel ISA-L 2.29.0
######
# hadolint ignore=DL3003,DL3008
RUN mkdir -p /opt/isa-l-src \
    && apt-get -q update \
    && apt-get install -y --no-install-recommends automake yasm \
    && apt-get clean \
    && curl -L -s -S \
      https://github.com/intel/isa-l/archive/v2.29.0.tar.gz \
      -o /opt/isa-l.tar.gz \
    && tar xzf /opt/isa-l.tar.gz --strip-components 1 -C /opt/isa-l-src \
    && cd /opt/isa-l-src \
    && ./autogen.sh \
    && ./configure \
    && make "-j$(nproc)" \
    && make install \
    && cd /root \
    && rm -rf /opt/isa-l-src

###
# Avoid out of memory errors in builds
###
ENV MAVEN_OPTS -Xms256m -Xmx1536m

# Skip gpg verification when downloading Yetus via yetus-wrapper
ENV HADOOP_SKIP_YETUS_VERIFICATION true

###
# Everything past this point is either not needed for testing or breaks Yetus.
# So tell Yetus not to read the rest of the file:
# YETUS CUT HERE
###

# Add a welcome message and environment checks.
COPY hadoop_env_checks.sh /root/hadoop_env_checks.sh
RUN chmod 755 /root/hadoop_env_checks.sh
# hadolint ignore=SC2016
RUN echo '${HOME}/hadoop_env_checks.sh' >> /root/.bashrc
