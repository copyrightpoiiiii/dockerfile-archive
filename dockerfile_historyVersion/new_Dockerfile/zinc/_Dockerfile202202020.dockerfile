# syntax=docker/dockerfile:experimental
############################
# STEP 1 build executable binary
############################
# FROM golang:alpine AS builder
FROM --platform=$BUILDPLATFORM public.ecr.aws/docker/library/golang:latest as builder
ARG VERSION
ARG COMMIT_HASH
ARG BUILD_DATE
ARG TARGETOS
ARG TARGETARCH

RUN update-ca-certificates
# RUN apk update && apk add --no-cache git
# Create appuser.
ENV USER=appuser
ENV UID=10001 
# See https://stackoverflow.com/a/55757473/12429735RUN 
RUN adduser \    
    --disabled-password \    
    --gecos "" \    
    --home "/nonexistent" \    
    --shell "/sbin/nologin" \    
    --no-create-home \    
    --uid "${UID}" \    
    "${USER}"
WORKDIR $GOPATH/src/github.com/prabhatsharma/zinc/
COPY . .
# Fetch dependencies.
# Using go get.
RUN go get -d -v
# Using go mod.
# RUN go mod download
# RUN go mod verify
# Build the binary.
# to tackle error standard_init_linux.go:207: exec user process caused "no such file or directory" set CGO_ENABLED=0. 
# CGO_ENABLED=0 builds a statically linked binary.
# docs for -ldflags at https://pkg.go.dev/cmd/link
#       -w : Omit the DWARF symbol table.
#       -s : Omit the symbol table and debug information.
#       Omit the symbol table and debug information will reduce the binary size.
# RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o zinc cmd/zinc/main.go
ENV VERSION=$VERSION
ENV COMMIT_HASH=$COMMIT_HASH
ENV BUILD_DATE=$BUILD_DATE

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -ldflags="-s -w -X github.com/prabhatsharma/zinc/pkg/meta/v1.Version=${VERSION} -X github.com/prabhatsharma/zinc/pkg/meta/v1.CommitHash=${COMMIT_HASH} -X github.com/prabhatsharma/zinc/pkg/meta/v1.BuildDate=${BUILD_DATE}" -o zinc cmd/zinc/main.go
############################
# STEP 2 build a small image
############################
# FROM public.ecr.aws/lts/ubuntu:latest
FROM scratch
# Import the user and group files from the builder.
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group

# Copy the ssl certificates
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

# Copy our static executable.
COPY --from=builder  /go/src/github.com/prabhatsharma/zinc/zinc /go/bin/zinc

# Use an unprivileged user.
USER appuser:appuser
# Port on which the service will be exposed.
EXPOSE 4080
# Run the zinc binary.
ENTRYPOINT ["/go/bin/zinc"]
