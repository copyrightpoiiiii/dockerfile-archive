FROM alpine

ARG VARNISH_VERSION=6.6.1
ARG DIST_SHA512=af3ee1743af2ede2d3efbb73e5aa9b42c7bbd5f86163ec338c8afd1989c3e51ff3e1b40bed6b72224b5d339a74f22d6e5f3c3faf2fedee8ab4715307ed5d871b
ARG PKG_COMMIT=1f139121b5bce0b5b8f5d104224e14880a921b6b

RUN set -e;\
    apk add -q --no-progress --update tar alpine-sdk sudo git; \
    git clone https://github.com/varnishcache/pkg-varnish-cache.git; \
    cd pkg-varnish-cache/alpine; \
    git checkout $PKG_COMMIT; \
    sed -i APKBUILD \
        -e "s/pkgver=@VERSION@/pkgver=$VARNISH_VERSION/" \
 -e 's@^source=.*@source="http://varnish-cache.org/_downloads/varnish-$pkgver.tgz"@' \
 -e "s/^sha512sums=.*/sha512sums=\"$DIST_SHA512  varnish-\$pkgver.tgz\"/"; \
    cat APKBUILD; \
    adduser -D builder; \
    echo "builder ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers; \
    addgroup builder abuild; \
    su builder -c "abuild-keygen -nai"; \
    chown builder -R .; \
    su builder -c "abuild -r";\
    mkdir /tmp/pkgs; \
    cp ~builder/packages/pkg-varnish-cache/*/*.apk /tmp/pkgs

FROM alpine

COPY --from=0 /tmp/pkgs /tmp
COPY --from=0 /pkg-varnish-cache/systemd/varnishreload /usr/bin/

RUN set -e; \
    apk add --allow-untrusted /tmp/*.apk; \
    rm -rf /tmp/*.apk; \
    echo -e 'vcl 4.1;\nbackend default none;' > /etc/varnish/default.vcl

WORKDIR /etc/varnish

COPY scripts/ /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/docker-varnish-entrypoint"]

EXPOSE 80 8443
CMD []
