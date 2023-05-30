# AUTOMATICALLY GENERATED
# DO NOT EDIT THIS FILE DIRECTLY, USE /Dockerfile.template.erb

# To set multiarch build for Docker hub automated build.
FROM golang:alpine AS builder
WORKDIR /go
ENV QEMU_DOWNLOAD_SHA256 47ae430b0e7c25e1bde290ac447a720e2ea6c6e78cd84e44847edda289e020a8
RUN apk add curl --no-cache
RUN curl -sL -o qemu-3.0.0+resin-arm.tar.gz https://github.com/balena-io/qemu/releases/download/v3.0.0%2Bresin/qemu-3.0.0+resin-arm.tar.gz && echo "$QEMU_DOWNLOAD_SHA256 *qemu-3.0.0+resin-arm.tar.gz" | sha256sum -c - | tar zxvf qemu-3.0.0+resin-arm.tar.gz -C . && mv qemu-3.0.0+resin-arm/qemu-arm-static .

FROM arm32v7/ruby:3.1-slim-bullseye
COPY --from=builder /go/qemu-arm-static /usr/bin/
LABEL maintainer "Fluentd developers <fluentd@googlegroups.com>"
LABEL Description="Fluentd docker image" Vendor="Fluent Organization" Version="1.15.0"
ARG CROSS_BUILD_START="cross-build-start"
ARG CROSS_BUILD_END="cross-build-end"
RUN [ ${CROSS_BUILD_START} ]
ENV TINI_VERSION=0.18.0

# Do not split this into multiple RUN!
# Docker creates a layer for every RUN-Statement
# therefore an 'apt-get purge' has no effect
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
            ca-certificates \
 && buildDeps=" \
      make gcc g++ libc-dev \
      wget bzip2 gnupg dirmngr \
    " \
 && apt-get install -y --no-install-recommends $buildDeps \
 && echo 'gem: --no-document' >> /etc/gemrc \
 && gem install oj -v 3.10.18 \
 && gem install json -v 2.4.1 \
 && gem install async-http -v 0.54.0 \
 && gem install fluentd -v 1.15.0 \
 && dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
 && wget -O /usr/local/bin/tini "https://github.com/krallin/tini/releases/download/v$TINI_VERSION/tini-$dpkgArch" \
 && wget -O /usr/local/bin/tini.asc "https://github.com/krallin/tini/releases/download/v$TINI_VERSION/tini-$dpkgArch.asc" \
 && export GNUPGHOME="$(mktemp -d)" \
 && gpg --batch --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 6380DC428747F6C393FEACA59A84159D7001A4E5 \
 && gpg --batch --verify /usr/local/bin/tini.asc /usr/local/bin/tini \
 && rm -r /usr/local/bin/tini.asc \
 && chmod +x /usr/local/bin/tini \
 && tini -h \
 && wget -O /tmp/jemalloc-5.3.0.tar.bz2 https://github.com/jemalloc/jemalloc/releases/download/5.3.0/jemalloc-5.3.0.tar.bz2 \
 && cd /tmp && tar -xjf jemalloc-5.3.0.tar.bz2 && cd jemalloc-5.3.0/ \
 && ./configure && make \
 && mv lib/libjemalloc.so.2 /usr/lib \
 && apt-get purge -y --auto-remove \
                  -o APT::AutoRemove::RecommendsImportant=false \
                  $buildDeps \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /tmp/* /var/tmp/* /usr/lib/ruby/gems/*/cache/*.gem /usr/lib/ruby/gems/3.*/gems/fluentd-*/test

RUN groupadd -r fluent && useradd -r -g fluent fluent \
    # for log storage (maybe shared with host)
    && mkdir -p /fluentd/log \
    # configuration/plugins path (default: copied from .)
    && mkdir -p /fluentd/etc /fluentd/plugins \
    && chown -R fluent /fluentd && chgrp -R fluent /fluentd


COPY fluent.conf /fluentd/etc/
COPY entrypoint.sh /bin/


ENV FLUENTD_CONF="fluent.conf"

ENV LD_PRELOAD="/usr/lib/libjemalloc.so.2"
EXPOSE 24224 5140

USER fluent
ENTRYPOINT ["tini",  "--", "/bin/entrypoint.sh"]
CMD ["fluentd"]

RUN [ ${CROSS_BUILD_END} ]