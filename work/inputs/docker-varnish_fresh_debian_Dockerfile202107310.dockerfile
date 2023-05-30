FROM debian:buster-slim

RUN set -e; \
    apt-get update; \
    apt-get install -y curl dpkg-dev debhelper devscripts equivs git pkg-config apt-utils fakeroot; \
    git clone https://github.com/varnishcache/pkg-varnish-cache.git; \
    cd pkg-varnish-cache; \
    git checkout 1f139121b5bce0b5b8f5d104224e14880a921b6b; \
    rm -rf .git; \
    curl http://varnish-cache.org/_downloads/varnish-6.6.1.tgz -o /tmp/orig.tgz; \
    sha512sum /tmp/orig.tgz; \
    [ "`sha512sum /tmp/orig.tgz`" = "af3ee1743af2ede2d3efbb73e5aa9b42c7bbd5f86163ec338c8afd1989c3e51ff3e1b40bed6b72224b5d339a74f22d6e5f3c3faf2fedee8ab4715307ed5d871b  /tmp/orig.tgz" ]; \
    tar xavf /tmp/orig.tgz --strip 1; \
    sed -i -e "s|@VERSION@|6.6.1|"  "debian/changelog"; \
    yes | mk-build-deps --install debian/control || true; \
    tar cvzf debian.tar.gz debian --dereference; tar xavf debian.tar.gz; \
    sed -i '' debian/varnish*; \
    dpkg-buildpackage -us -uc -j16; \
    mkdir /tmp/pkgs; \
    mv ../*.deb /tmp/pkgs

FROM debian:buster-slim

ENV VARNISH_SIZE 100M

COPY --from=0 /tmp/pkgs /tmp

RUN set -e;\
    export DEBIAN_FRONTEND=noninteractive; \
    export DEBCONF_NONINTERACTIVE_SEEN=true; \
    apt-get update; \
    apt-get install -y /tmp/*.deb; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /etc/varnish

COPY scripts/ /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/docker-varnish-entrypoint"]

EXPOSE 80 8443
CMD []