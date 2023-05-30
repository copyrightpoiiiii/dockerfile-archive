# AUTOMATICALLY GENERATED
# DO NOT EDIT THIS FILE DIRECTLY, USE /Dockerfile.template.erb

# To set multiarch build for Docker hub automated build.
FROM golang:alpine AS builder
WORKDIR /go
ENV QEMU_DOWNLOAD_SHA256 5db25cccb40ac7b1ca857653b883376b931d91b06ff34ffe70dcf6180bd07bb8
RUN apk add curl --no-cache
RUN curl -sL -o qemu-6.0.0.balena1-aarch64.tar.gz https://github.com/balena-io/qemu/releases/download/v6.0.0%2Bbalena1/qemu-6.0.0.balena1-aarch64.tar.gz && echo "$QEMU_DOWNLOAD_SHA256 *qemu-6.0.0.balena1-aarch64.tar.gz" | sha256sum -c - | tar zxvf qemu-6.0.0.balena1-aarch64.tar.gz -C . && mv qemu-6.0.0+balena1-aarch64/qemu-aarch64-static .

FROM arm64v8/ruby:3.1-slim-bullseye
COPY --from=builder /go/qemu-aarch64-static /usr/bin/
LABEL maintainer "Fluentd developers <fluentd@googlegroups.com>"
LABEL Description="Fluentd docker image" Vendor="Fluent Organization" Version="1.15.1"
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
 && gem install oj -v 3.13.19 \
 && gem install json -v 2.6.2 \
 && gem install async -v 1.30.3 \
 && gem install async-http -v 0.56.6 \
 && gem install fluentd -v 1.15.1 \
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
