FROM golang:1.10 AS builder

WORKDIR /go/src/github.com/syncthing/syncthing
COPY . .

ENV CGO_ENABLED=0
ENV BUILD_HOST=syncthing.net
ENV BUILD_USER=docker
RUN rm -f syncthing && go run build.go build syncthing

FROM alpine

EXPOSE 8384 22000 21027/udp

VOLUME ["/var/syncthing"]

RUN apk add --no-cache ca-certificates

COPY --from=builder /go/src/github.com/syncthing/syncthing/syncthing /bin/syncthing

RUN apk add --no-cache su-exec

ENV STNOUPGRADE=1
ENV PUSR=syncthing
ENV PUID=1000
ENV PGRP=syncthing
ENV PGID=1000

HEALTHCHECK --interval=1m --timeout=10s \
  CMD nc -z localhost 8384 || exit 1

ENTRYPOINT true \
 && ( getent group "${PGRP}" >/dev/null \
      || addgroup \
          -g "${PGID}" \
          "${PGRP}" \
    ) \
 && ( getent passwd "${PUSR}" >/dev/null \
      || adduser \
          -h /var/syncthing \
          -G "${PGRP}" \
          -u "${PUID}" \
          "${PUSR}" \
    ) \
 && chown "${PUSR}:${PGRP}" /var/syncthing \
 && su-exec "${PUSR}:${PGRP}" \
     /bin/syncthing \
       -home /var/syncthing/config \
       -gui-address 0.0.0.0:8384 \
 && true
