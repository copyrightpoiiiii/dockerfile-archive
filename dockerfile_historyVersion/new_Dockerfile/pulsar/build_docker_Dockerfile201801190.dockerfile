#
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

FROM ubuntu:16.04

# prepare the directory for pulsar related files
RUN mkdir /pulsar
ADD protobuf.patch /pulsar

RUN apt-get update
RUN apt-get install -y maven tig g++ cmake libssl-dev libcurl4-openssl-dev \
                liblog4cxx-dev libprotobuf-dev libboost-all-dev google-mock libgtest-dev \
                libjsoncpp-dev libxml2-utils protobuf-compiler wget \
                curl doxygen openjdk-8-jdk-headless clang-format-4.0

# Compile and install gtest
RUN cd /usr/src/gtest && cmake . && make && cp libgtest.a /usr/lib

# Compile and install google-mock
RUN cd /usr/src/gmock && cmake . && make && cp libgmock.a /usr/lib

# Include gtest parallel to speed up unit tests
RUN git clone https://github.com/google/gtest-parallel.git

ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64

## Website build dependencies

# Install Ruby-2.4.1
RUN apt-get install -y
RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB && \
    (curl -sSL https://get.rvm.io | bash -s stable)
ENV PATH "$PATH:/usr/local/rvm/bin"
RUN rvm install 2.4.1

# Install PIP and PDoc
RUN wget https://bootstrap.pypa.io/get-pip.py && python get-pip.py
RUN pip install pdoc

# Protogen doc generator
RUN wget https://github.com/pseudomuto/protoc-gen-doc/releases/download/v1.0.0-alpha/protoc-gen-doc-1.0.0-alpha.linux-amd64.go1.8.1.tar.gz && \
    tar xvfz protoc-gen-doc-1.0.0-alpha.linux-amd64.go1.8.1.tar.gz && \
    cp protoc-gen-doc-1.0.0-alpha.linux-amd64.go1.8.1/protoc-gen-doc /usr/local/bin && \
    rm protoc-gen-doc-1.0.0-alpha.linux-amd64.go1.8.1.tar.gz

# Build the patched protoc
RUN git clone https://github.com/google/protobuf.git /pulsar/protobuf && \
    cd /pulsar/protobuf && \
    git checkout v2.4.1 && \
    patch -p1 < /pulsar/protobuf.patch && \
    autoreconf --install && \
    ./configure && \
    make
