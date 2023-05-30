# Multi-stage builder to avoid polluting users environment with wrong 
# architecture binaries.  Since this binary is used in an alpine container, 
# we're explicitly compiling for 'linux/amd64'
ARG VERSION=1.13.10

FROM golang:${VERSION} AS builder

ARG CGO_ENABLED=0
ARG BUILD_TAGS

WORKDIR /go/src/github.com/hashicorp/vault
COPY . .

RUN make bootstrap \
  && CGO_ENABLED=$CGO_ENABLED BUILD_TAGS='$BUILD_TAGS' VAULT_DEV_BUILD=1 XC_OSARCH='linux/amd64' sh -c "'./scripts/build.sh'"

# Docker Image

FROM alpine:3.10

# Create a vault user and group first so the IDs get set the same way,
# even as the rest of this may change over time.
RUN addgroup vault && \
    adduser -S -G vault vault

# Set up certificates, our base tools, and Vault.
RUN set -eux; \
    apk add --no-cache ca-certificates libcap su-exec dumb-init tzdata

COPY --from=builder /go/bin/vault /bin/vault

# /vault/logs is made available to use as a location to store audit logs, if
# desired; /vault/file is made available to use as a location with the file
# storage backend, if desired; the server will be started with /vault/config as
# the configuration directory so you can add additional config files in that
# location.
RUN mkdir -p /vault/logs && \
    mkdir -p /vault/file && \
    mkdir -p /vault/config && \
    chown -R vault:vault /vault

# Expose the logs directory as a volume since there's potentially long-running
# state in there
VOLUME /vault/logs

# Expose the file directory as a volume since there's potentially long-running
# state in there
VOLUME /vault/file

# 8200/tcp is the primary interface that applications use to interact with
# Vault.
EXPOSE 8200

# The entry point script uses dumb-init as the top-level process to reap any
# zombie processes created by Vault sub-processes.
#
# For production derivatives of this container, you should add the IPC_LOCK
# capability so that Vault can mlock memory.
COPY ./scripts/docker/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

# By default you'll get a single-node development server that stores everything
# in RAM and bootstraps itself. Don't use this configuration for production.
CMD ["server", "-dev"]