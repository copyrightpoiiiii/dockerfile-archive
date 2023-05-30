#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM debian:bullseye-slim

# roughly, https://salsa.debian.org/haproxy-team/haproxy/-/blob/732b97ae286906dea19ab5744cf9cf97c364ac1d/debian/haproxy.postinst#L5-6
RUN set -eux; \
 groupadd --gid 99 --system haproxy; \
 useradd \
  --gid haproxy \
  --home-dir /var/lib/haproxy \
  --no-create-home \
  --system \
  --uid 99 \
  haproxy \
 ; \
 mkdir /var/lib/haproxy; \
 chown haproxy:haproxy /var/lib/haproxy

ENV HAPROXY_VERSION 2.5.7
ENV HAPROXY_URL https://www.haproxy.org/download/2.5/src/haproxy-2.5.7.tar.gz
ENV HAPROXY_SHA256 e29f6334c6bdb521f63ddf335e2621bd2164503b99cf1f495b6f56ff9f3c164e

# see https://sources.debian.net/src/haproxy/jessie/debian/rules/ for some helpful navigation of the possible "make" arguments
RUN set -eux; \
 \
 savedAptMark="$(apt-mark showmanual)"; \
 apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates \
  gcc \
  libc6-dev \
  liblua5.3-dev \
  libpcre2-dev \
  libssl-dev \
  make \
  wget \
 ; \
 rm -rf /var/lib/apt/lists/*; \
 \
 wget -O haproxy.tar.gz "$HAPROXY_URL"; \
 echo "$HAPROXY_SHA256 *haproxy.tar.gz" | sha256sum -c; \
 mkdir -p /usr/src/haproxy; \
 tar -xzf haproxy.tar.gz -C /usr/src/haproxy --strip-components=1; \
 rm haproxy.tar.gz; \
 \
 makeOpts=' \
  TARGET=linux-glibc \
  USE_GETADDRINFO=1 \
  USE_LUA=1 LUA_INC=/usr/include/lua5.3 \
  USE_OPENSSL=1 \
  USE_PCRE2=1 USE_PCRE2_JIT=1 \
  USE_PROMEX=1 \
  \
  EXTRA_OBJS=" \
  " \
 '; \
# https://salsa.debian.org/haproxy-team/haproxy/-/commit/53988af3d006ebcbf2c941e34121859fd6379c70
 dpkgArch="$(dpkg --print-architecture)"; \
 case "$dpkgArch" in \
  armel) makeOpts="$makeOpts ADDLIB=-latomic" ;; \
 esac; \
 \
 nproc="$(nproc)"; \
 eval "make -C /usr/src/haproxy -j '$nproc' all $makeOpts"; \
 eval "make -C /usr/src/haproxy install-bin $makeOpts"; \
 \
 mkdir -p /usr/local/etc/haproxy; \
 cp -R /usr/src/haproxy/examples/errorfiles /usr/local/etc/haproxy/errors; \
 rm -rf /usr/src/haproxy; \
 \
 apt-mark auto '.*' > /dev/null; \
 [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; \
 find /usr/local -type f -executable -exec ldd '{}' ';' \
  | awk '/=>/ { print $(NF-1) }' \
  | sort -u \
  | xargs -r dpkg-query --search \
  | cut -d: -f1 \
  | sort -u \
  | xargs -r apt-mark manual \
 ; \
 apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
 \
# smoke test
 haproxy -v

# https://www.haproxy.org/download/1.8/doc/management.txt
# "4. Stopping and restarting HAProxy"
# "when the SIGTERM signal is sent to the haproxy process, it immediately quits and all established connections are closed"
# "graceful stop is triggered when the SIGUSR1 signal is sent to the haproxy process"
STOPSIGNAL SIGUSR1

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

USER haproxy
CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]