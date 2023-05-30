FROM alpine:3

ENV VARNISH_SIZE 100M

RUN set -e;\
    BASE_PKGS="tar alpine-sdk sudo git"; \
    apk add -q --no-progress --update $BASE_PKGS; \
    git clone https://github.com/varnishcache/pkg-varnish-cache.git; \
    cd pkg-varnish-cache/alpine; \
    git checkout 1f139121b5bce0b5b8f5d104224e14880a921b6b; \
    sed -i APKBUILD \
        -e "s/pkgver=@VERSION@/pkgver=6.6.1/" \
 -e 's@^source=.*@source="http://varnish-cache.org/_downloads/varnish-$pkgver.tgz"@' \
 -e "s/^sha512sums=.*/sha512sums=\"af3ee1743af2ede2d3efbb73e5aa9b42c7bbd5f86163ec338c8afd1989c3e51ff3e1b40bed6b72224b5d339a74f22d6e5f3c3faf2fedee8ab4715307ed5d871b  varnish-\$pkgver.tgz\"/"; \
    cat APKBUILD; \
    adduser -D builder; \
    echo "builder ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers; \
    addgroup builder abuild; \
    su builder -c "abuild-keygen -nai"; \
    chown builder -R .; \
    su builder -c "abuild -r";\
    apk add --allow-untrusted ~builder/packages/pkg-varnish-cache/*/*.apk; \
    echo -e 'vcl 4.1;\nbackend default none;' > /etc/varnish/default.vcl; \
    cp /pkg-varnish-cache/systemd/varnishreload /usr/bin/; \
    apk del $BASE_PKGS; \
    rm -rf ~builder /pkg-varnish-cache; \
    sed -i '/^builder/d' /etc/sudoers; \
    deluser --remove-home builder

WORKDIR /etc/varnish

COPY scripts/ /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/docker-varnish-entrypoint"]

EXPOSE 80 8443
CMD []
