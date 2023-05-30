FROM golang:1.12-alpine AS builder
ENV CGO_ENABLED=0 GOOS=linux GOARCH=amd64
COPY go.mod go.sum /app/
WORKDIR /app/
RUN apk --no-cache add git upx
RUN go mod download
COPY . /app/
RUN go build -ldflags "-X main.version=$(git describe --tags --abbrev=0)" -a -o /trivy cmd/trivy/main.go
RUN upx --lzma --best /trivy

FROM alpine:3.10
RUN apk --no-cache add ca-certificates git rpm
COPY --from=builder /trivy /usr/local/bin/trivy

ENTRYPOINT ["trivy"]
