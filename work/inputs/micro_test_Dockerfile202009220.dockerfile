FROM alpine:latest
RUN apk add make git go gcc libtool musl-dev curl bash

# Configure Go
ENV GOROOT /usr/lib/go
ENV GOPATH /go
ENV PATH /go/bin:$PATH

RUN mkdir -p ${GOPATH}/src ${GOPATH}/bin

RUN apk add ca-certificates && \
    rm -rf /var/cache/apk/* /tmp/* && \
    [ ! -e /etc/nsswitch.conf ] && echo 'hosts: files dns' > /etc/nsswitch.conf

RUN         apk add --update ca-certificates openssl tar && \
            wget https://github.com/coreos/etcd/releases/download/v3.4.7/etcd-v3.4.7-linux-amd64.tar.gz && \
            tar xzvf etcd-v3.4.7-linux-amd64.tar.gz && \
            mv etcd-v3.4.7-linux-amd64/etcd* /bin/ && \
            apk del --purge tar openssl && \
            rm -Rf etcd-v3.4.7-linux-amd64* /var/cache/apk/*
VOLUME      /data
EXPOSE      2379 2380 4001 7001
ADD         scripts/run-etcd.sh /bin/run.sh

COPY . .
RUN go get github.com/micro/services
RUN go get github.com/micro/services/helloworld
RUN bash -c 'for d in $(find test -name "main.go" | xargs -n 1 dirname); do pushd $d && go get && popd; done'

COPY ./micro /micro
ENTRYPOINT ["sh", "/bin/run.sh"]
