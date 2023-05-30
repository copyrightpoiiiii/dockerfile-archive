# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
ARG GO_VER
ARG ALPINE_VER
ARG JAVA_VER
ARG NODE_VER
FROM golang:${GO_VER}-alpine${ALPINE_VER} as golang
ARG CHAINTOOL_RELEASE
ARG CHAINTOOL_URL=https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric/chaintool-${CHAINTOOL_RELEASE}/hyperledger-fabric-chaintool-${CHAINTOOL_RELEASE}.jar
RUN apk add --no-cache \
 gcc \
 musl-dev \
 git \
 bash \
 curl \
 make;
ADD . $GOPATH/src/github.com/hyperledger/fabric
WORKDIR $GOPATH/src/github.com/hyperledger/fabric
ENV EXECUTABLES go git curl
RUN make gotool.protoc-gen-go \
 && go get -u github.com/kardianos/govendor \
 && mkdir $GOPATH/src/input \
 && cp images/ccenv/main.go $GOPATH/src/input/. \
 && cd $GOPATH/src/input \
 && $GOPATH/bin/govendor init \
 && $GOPATH/bin/govendor add +external github.com/hyperledger/fabric/core/chaincode/shim \
 && rm $GOPATH/src/input/vendor/vendor.json \
 && curl -fL ${CHAINTOOL_URL} > /usr/local/bin/chaintool \
 && chmod +x /usr/local/bin/chaintool

FROM node:${NODE_VER}-alpine as node

FROM openjdk:${JAVA_VER}-jdk-alpine${ALPINE_VER}
RUN apk add --no-cache \
 make \
 g++ \
 python \
 gcc \
 musl-dev \
 libtool \
 protobuf \
 git;
ENV PATH=/usr/local/go/bin:${PATH}
ENV GOPATH=/go
RUN mkdir -p /chaincode/output \
 && mkdir -p /chaincode/input \
 && mkdir -p /go/src \
 && mkdir -p /go/bin \
 && mkdir -p /go/pkg
COPY --from=node /usr/local/bin /usr/local/bin
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node /usr/local/include/node /usr/local/include/node
COPY --from=golang /usr/local/go /usr/local/go
COPY --from=golang /usr/local/bin/chaintool /usr/local/bin/chaintool
COPY --from=golang /go/bin /usr/local/bin
COPY --from=golang /go/src/input/vendor $GOPATH/src
