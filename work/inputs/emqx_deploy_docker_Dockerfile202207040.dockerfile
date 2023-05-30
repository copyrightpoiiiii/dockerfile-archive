ARG BUILD_FROM=ghcr.io/emqx/emqx-builder/5.0-17:1.13.4-24.2.1-1-debian11
ARG RUN_FROM=debian:11-slim
FROM ${BUILD_FROM} AS builder

COPY . /emqx

ARG EMQX_NAME=emqx
ENV EMQX_RELUP=false

RUN export PROFILE="$EMQX_NAME" \
    && export EMQX_NAME=${EMQX_NAME%%-elixir} \
    && export EMQX_LIB_PATH="_build/$EMQX_NAME/lib" \
    && export EMQX_REL_PATH="/emqx/_build/$EMQX_NAME/rel/emqx" \
    && export EMQX_REL_FORM='docker' \
    && cd /emqx \
    && rm -rf $EMQX_LIB_PATH \
    && make $PROFILE \
    && mkdir -p /emqx-rel \
    && mv $EMQX_REL_PATH /emqx-rel

FROM $RUN_FROM

# Elixir complains if runs without UTF-8
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

COPY deploy/docker/docker-entrypoint.sh /usr/bin/
COPY --from=builder /emqx-rel/emqx /opt/emqx

RUN ln -s /opt/emqx/bin/* /usr/local/bin/

RUN apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates procps; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt/emqx

RUN groupadd -r -g 1000 emqx; \
    useradd -r -m -u 1000 -g emqx emqx; \
    chgrp -Rf emqx /opt/emqx; \
    chmod -Rf g+w /opt/emqx; \
    chown -Rf emqx /opt/emqx

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
# - 4370 default Erlang distribution port
# - 5369 for backplain gen_rpc
EXPOSE 1883 8081 8083 8084 8883 11883 18083 4370 5369

ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]

CMD ["/opt/emqx/bin/emqx", "foreground"]
