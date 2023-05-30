FROM golang:1.19.0-alpine@sha256:0e78fc17d9b4428bc6b9c07aa49c819541a99cd0c0121c4de9c68feecfea825b

RUN apk add --no-cache bash \
 curl \
 docker-cli \
 docker-cli-buildx \
 git \
 gpg \
 mercurial \
 make \
 openssh-client \
 build-base \
 tini

# install cosign
COPY --from=gcr.io/projectsigstore/cosign:v1.10.0@sha256:a719237925984033fb72685c1998d922c903bbe62464f6d401b5108d3195bb94 /ko-app/cosign /usr/local/bin/cosign

ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]
CMD [ "-h" ]

COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY goreleaser_*.apk /tmp/
RUN apk add --no-cache --allow-untrusted /tmp/goreleaser_*.apk