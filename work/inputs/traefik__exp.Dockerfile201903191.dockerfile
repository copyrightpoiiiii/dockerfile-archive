# WEBUI
FROM node:8.15.0 as webui

ENV WEBUI_DIR /src/webui
RUN mkdir -p $WEBUI_DIR

COPY ./webui/ $WEBUI_DIR/

WORKDIR $WEBUI_DIR
RUN yarn install

RUN npm run build

# BUILD
FROM golang:1.12-alpine as gobuild

RUN apk --update upgrade \
&& apk --no-cache --no-progress add git mercurial bash gcc musl-dev curl tar \
&& rm -rf /var/cache/apk/*

RUN mkdir -p /usr/local/bin \
    && curl -fsSL -o /usr/local/bin/go-bindata https://github.com/containous/go-bindata/releases/download/v1.0.0/go-bindata \
    && chmod +x /usr/local/bin/go-bindata

WORKDIR /go/src/github.com/containous/traefik
COPY . /go/src/github.com/containous/traefik

COPY --from=webui /src/static/ /go/src/github.com/containous/traefik/static/

RUN ./script/make.sh binary

## IMAGE
FROM scratch

COPY script/ca-certificates.crt /etc/ssl/certs/
COPY --from=gobuild /go/src/github.com/containous/traefik/dist/traefik /

EXPOSE 80
VOLUME ["/tmp"]

ENTRYPOINT ["/traefik"]
