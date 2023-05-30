FROM golang:1.18.2 as builder

ARG RELEASE_VERSION

# Buf plugins must be built for linux/amd64
ENV GOOS=linux GOARCH=amd64 CGO_ENABLED=0
RUN go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@${RELEASE_VERSION}

FROM scratch

COPY --from=builder /go/bin/protoc-gen-grpc-gateway /usr/local/bin/protoc-gen-grpc-gateway

ENTRYPOINT ["/usr/local/bin/protoc-gen-grpc-gateway"]
