FROM ubuntu:20.04

ARG ARTIFACTORY_CREDS
ARG DEVKIT_NAME=devkit-fedora-gcc
ARG DEVKIT_VERSION=21-8.3.0

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -qq -y --no-install-recommends \
autoconf \
ca-certificates \
ccache \
cpio \
curl \
file \
git \
graphviz \
libasound2-dev \
libcups2-dev \
libelf-dev \
libfontconfig1-dev \
libfreetype6-dev \
libx11-dev \
libxext-dev \
libxrandr-dev \
libxrender-dev \
libxt-dev \
libxtst-dev \
make \
pandoc \
patch \
python3 \
python3-pip \
unzip \
wget \
zip

RUN useradd -ms /bin/bash jenkinsa -u 1000
RUN useradd -ms /bin/bash jenkinsb -u 1001
RUN useradd -ms /bin/bash jenkinsc -u 1002

RUN pip3 install requests

WORKDIR /opt/devkits
ADD https://$ARTIFACTORY_CREDS@common.repositories.cloud.sap/artifactory/sapmachine-mvn/io/sapmachine/build/devkit/linux-aarch64/${DEVKIT_NAME}/${DEVKIT_VERSION}/${DEVKIT_NAME}-${DEVKIT_VERSION}.tar.gz /opt/devkits/
WORKDIR /opt/devkits/${DEVKIT_NAME}-${DEVKIT_VERSION}
RUN tar xvzf ../${DEVKIT_NAME}-${DEVKIT_VERSION}.tar.gz

WORKDIR /usr/include
RUN find . -name clock_t.h

WORKDIR /tmp
ADD https://raw.githubusercontent.com/tstuefe/tinyreaper/master/tinyreaper.c /tmp/
RUN /opt/devkits/${DEVKIT_NAME}-${DEVKIT_VERSION}/bin/gcc -I/usr/include -I/usr/include/arm64-linux-gnu /tmp/tinyreaper.c -o /opt/tinyreaper && \
    chmod +x /opt/tinyreaper && \
    rm /tmp/tinyreaper.c