FROM debian:buster
LABEL maintainer "Jessie Frazelle <jess@linux.com>"

RUN apt-get update && apt-get install -y \
 debootstrap \
 --no-install-recommends \
 && rm -rf /var/lib/apt/lists/*

ENTRYPOINT [ "debootstrap" ]
