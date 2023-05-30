FROM golang:alpine

WORKDIR /go/src/github.com/flipped-aurora/gin-vue-admin
COPY . .

RUN go generate && go env && go build -o server .

FROM alpine:latest
LABEL MAINTAINER="SliverHorn@sliver_horn@qq.com"

WORKDIR /go/src/github.com/flipped-aurora/gin-vue-admin

COPY --from=0 /go/src/github.com/flipped-aurora/gin-vue-admin ./

EXPOSE 8888

ENTRYPOINT ./server -c config.docker.yaml
