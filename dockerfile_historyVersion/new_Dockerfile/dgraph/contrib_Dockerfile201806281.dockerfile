# This file is used to add the nightly Dgraph binaries and assets to Dgraph base
# image.

# Command to build - docker build -t dgraph/dgraph:nightly .

FROM debian:latest
MAINTAINER Dgraph Labs <contact@dgraph.io>

    # && apt-get update \
    # && apt-get install -y --no-install-recommends ca-certificates curl \
    # && rm -rf /var/lib/apt/lists/*

ADD /tmp/build/linux /usr/local/bin

EXPOSE 8080
EXPOSE 9080

RUN mkdir /dgraph
WORKDIR /dgraph

CMD ["dgraph"] # Shows the dgraph version and commands available.
