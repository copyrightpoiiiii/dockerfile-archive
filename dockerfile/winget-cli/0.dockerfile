# vim: ft=dockerfile
FROM alpine:3.7
MAINTAINER Ingy döt Net <ingy@ingy.net>

RUN apk update && \
    apk add --no-cache \
        autoconf \
        automake \
        build-base \
 cmake \
        git \
        libtool \
 perl-dev && \
    mkdir /libyaml

COPY . /libyaml/
WORKDIR /libyaml

ENV LD_LIBRARY_PATH=/libyaml/src/.libs

RUN ./bootstrap && \
    ./configure && \
    make && \
    make install

CMD ["bash"]
