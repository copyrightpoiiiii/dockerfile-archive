# FIXME: use tagged version once merged
ARG BUILD_FROM=ghcr.io/emqx/emqx-builder/elixir:1.13.1-24.1.5-3-alpine3.14
ARG RUN_FROM=alpine:3.14
FROM ${BUILD_FROM} AS builder

RUN apk add --no-cache \
    git \
    curl \
    gcc \
    g++ \
    make \
    perl \
    ncurses-dev \
    openssl-dev \
    coreutils \
    bsd-compat-headers \
    libc-dev \
    libstdc++ \
    bash \
    jq

COPY . /emqx

ARG EMQX_NAME=emqx

RUN if [[ "$EMQX_NAME" = *-elixir ]]; then \
      export EMQX_LIB_PATH="_build/prod/lib"; \
      export EMQX_REL_PATH="/emqx/_build/prod/rel/emqx"; \
    else \
      export EMQX_LIB_PATH="_build/$EMQX_NAME/lib"; \
      export EMQX_REL_PATH="/emqx/_build/$EMQX_NAME/rel/emqx"; \
    fi \
    && cd /emqx \
    && rm -rf $EMQX_LIB_PATH \
    && make $EMQX_NAME \
    && mkdir -p /emqx-rel \
    && mv $EMQX_REL_PATH /emqx-rel

FROM $RUN_FROM

COPY deploy/docker/docker-entrypoint.sh /usr/bin/
COPY --from=builder /emqx-rel/emqx /opt/emqx

RUN ln -s /opt/emqx/bin/* /usr/local/bin/
RUN apk add --no-cache curl ncurses-libs openssl sudo libstdc++ bash

WORKDIR /opt/emqx

RUN adduser -D -u 1000 emqx \
    && echo "emqx ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers

RUN chgrp -Rf emqx /opt/emqx && chmod -Rf g+w /opt/emqx \
    && chown -Rf emqx /opt/emqx

USER emqx

VOLUME ["/opt/emqx/log", "/opt/emqx/data"]

# emqx will occupy these port:
# - 1883 port for MQTT
# - 8081 for mgmt API
# - 8083 for WebSocket/HTTP
# - 8084 for WSS/HTTPS
# - 8883 port for MQTT(SSL)
# - 11883 port for internal MQTT/TCP
# - 18083 for dashboard
# - 4369 epmd (Erlang-distrbution port mapper daemon) listener (deprecated)
# - 4370 default Erlang distrbution port
# - 5369 for gen_rpc port mapping
# - 6369 6370 for distributed node
EXPOSE 1883 8081 8083 8084 8883 11883 18083 4369 4370 5369 6369 6370

ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]

CMD ["/opt/emqx/bin/emqx", "foreground"]
