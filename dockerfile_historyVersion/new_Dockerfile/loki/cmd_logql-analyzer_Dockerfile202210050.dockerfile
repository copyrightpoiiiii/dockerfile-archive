FROM golang:1.19.2 as build

COPY . /src/loki
WORKDIR /src/loki
RUN make clean && CGO_ENABLED=0 go build ./cmd/logql-analyzer/

FROM alpine:3.15.4

RUN apk add --no-cache ca-certificates

COPY --from=build /src/loki/logql-analyzer /usr/bin/logql-analyzer

ENTRYPOINT [ "/usr/bin/logql-analyzer" ]
