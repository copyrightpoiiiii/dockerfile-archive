# Copyright (C) 2019-2022 Zilliz. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance
# with the License. You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License
# is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied. See the License for the specific language governing permissions and limitations under the License.

FROM milvusdb/openblas:ubuntu20.04-20220825-4feedf1

RUN apt-get update && apt-get install -y --no-install-recommends wget curl ca-certificates gnupg2 && \
    wget -qO- "https://cmake.org/files/v3.18/cmake-3.18.6-Linux-x86_64.tar.gz" | tar --strip-components=1 -xz -C /usr/local && \
    apt-get update && apt-get install -y --no-install-recommends \
    g++ gcc gfortran git make ccache libssl-dev zlib1g-dev libboost-regex-dev libboost-program-options-dev libboost-system-dev \
    libboost-filesystem-dev libboost-serialization-dev python3-dev libboost-python-dev libcurl4-openssl-dev libtbb-dev clang-format-10 clang-tidy-10 lcov libtool m4 autoconf automake  && \
    apt-get remove --purge -y && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends libzstd-dev pkg-config 

# Install Go
ENV GOPATH /go
ENV GOROOT /usr/local/go
ENV GO111MODULE on
ENV PATH $GOPATH/bin:$GOROOT/bin:$PATH
RUN mkdir -p /usr/local/go && wget -qO- "https://golang.org/dl/go1.18.3.linux-amd64.tar.gz" | tar --strip-components=1 -xz -C /usr/local/go && \
    mkdir -p "$GOPATH/src" "$GOPATH/bin" && \
    curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b ${GOPATH}/bin v1.46.2 && \
    # export GO111MODULE=on && go get github.com/quasilyte/go-ruleguard/cmd/ruleguard@v0.2.1 && \
    go install github.com/ramya-rao-a/go-outline@latest && \
    go install golang.org/x/tools/gopls@latest && \
    go install github.com/uudashr/gopkgs/v2/cmd/gopkgs@latest && \
    go install github.com/go-delve/delve/cmd/dlv@latest && \
    go install honnef.co/go/tools/cmd/staticcheck@2022.1 && \
    go clean --modcache && \
    chmod -R 777 "$GOPATH" && chmod -R a+w $(go env GOTOOLDIR)

RUN ln -s /go/bin/dlv /go/bin/dlv-dap

RUN apt-get update && apt-get install -y --no-install-recommends \
    gdb gdbserver && \
    apt-get remove --purge -y && \
    rm -rf /var/lib/apt/lists/*

RUN echo 'root:root' | chpasswd

# refer: https://code.visualstudio.com/docs/remote/containers-advanced#_avoiding-extension-reinstalls-on-container-rebuild
RUN mkdir -p /home/milvus/.vscode-server/extensions \
        /home/milvus/.vscode-server-insiders/extensions \
    && chmod -R 777 /home/milvus

COPY --chown=0:0 build/docker/builder/entrypoint.sh /

RUN wget -qO- "https://github.com/jeffoverflow/autouseradd/releases/download/1.2.0/autouseradd-1.2.0-amd64.tar.gz" | tar xz -C / --strip-components 1

RUN wget -O /tini https://github.com/krallin/tini/releases/download/v0.19.0/tini && \
    chmod +x /tini

ENTRYPOINT [ "/tini", "--", "autouseradd", "--user", "milvus", "--", "/entrypoint.sh" ]
CMD ["tail", "-f", "/dev/null"]
