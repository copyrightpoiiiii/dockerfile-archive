FROM golang:1.19.2-alpine@sha256:2baa528036c1916b23de8b304083c68fb298c5661203055f2b1063390e3cdddb

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
COPY --from=gcr.io/projectsigstore/cosign:v1.12.1@sha256:ac8e08a2141e093f4fd7d1d0b05448804eb3771b66574b13ad73e31b460af64d /ko-app/cosign /usr/local/bin/cosign

ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]
CMD [ "-h" ]

COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY goreleaser_*.apk /tmp/
RUN apk add --no-cache --allow-untrusted /tmp/goreleaser_*.apk