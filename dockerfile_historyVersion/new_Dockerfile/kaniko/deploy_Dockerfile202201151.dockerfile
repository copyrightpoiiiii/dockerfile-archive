# Copyright 2018 Google, Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM golang:1.17
WORKDIR /src

# This arg is passed by docker buildx & contains the target CPU architecture (e.g., amd64, arm64, etc.)
ARG TARGETARCH

ENV GOARCH=$TARGETARCH
ENV CGO_ENABLED=0
ENV GOBIN=/usr/local/bin

# Get GCR credential helper
RUN go install github.com/GoogleCloudPlatform/docker-credential-gcr@4cdd60d0f2d8a69bc70933f4d7718f9c4e956ff8

# Get Amazon ECR credential helper
RUN go install github.com/awslabs/amazon-ecr-credential-helper/ecr-login/cli/docker-credential-ecr-login@v0.5.0

# Get ACR docker env credential helper
RUN go install github.com/chrismellard/docker-credential-acr-env@09e2b5a8ac86c3ec347b2473e42b34367d8fa419

# Add .docker config dir
RUN mkdir -p /kaniko/.docker

COPY . .
RUN \
    --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/go/pkg \
    make GOARCH=$TARGETARCH

# Generate latest ca-certificates

FROM debian:buster-slim AS certs

RUN \
  apt update && \
  apt install -y ca-certificates && \
  cat /etc/ssl/certs/* > /ca-certificates.crt

FROM scratch
COPY --from=0 /src/out/executor /kaniko/executor
COPY --from=0 /usr/local/bin/docker-credential-gcr /kaniko/docker-credential-gcr
COPY --from=0 /usr/local/bin/docker-credential-ecr-login /kaniko/docker-credential-ecr-login
COPY --from=0 /usr/local/bin/docker-credential-acr-env /kaniko/docker-credential-acr-env
COPY --from=certs /ca-certificates.crt /kaniko/ssl/certs/
COPY --from=0 /kaniko/.docker /kaniko/.docker
COPY files/nsswitch.conf /etc/nsswitch.conf
ENV HOME /root
ENV USER root
ENV PATH /usr/local/bin:/kaniko
ENV SSL_CERT_DIR=/kaniko/ssl/certs
ENV DOCKER_CONFIG /kaniko/.docker/
ENV DOCKER_CREDENTIAL_GCR_CONFIG /kaniko/.config/gcloud/docker_credential_gcr_config.json
WORKDIR /workspace

ENTRYPOINT ["/kaniko/executor"]