#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM alpine:3.16

# 70 is the standard uid/gid for "postgres" in Alpine
# https://git.alpinelinux.org/aports/tree/main/postgresql/postgresql.pre-install?h=3.12-stable
RUN set -eux; \
 addgroup -g 70 -S postgres; \
 adduser -u 70 -S -D -G postgres -H -h /var/lib/postgresql -s /bin/sh postgres; \
 mkdir -p /var/lib/postgresql; \
 chown -R postgres:postgres /var/lib/postgresql

# su-exec (gosu-compatible) is installed further down

# make the "en_US.UTF-8" locale so postgres will be utf-8 enabled by default
# alpine doesn't require explicit locale-file generation
ENV LANG en_US.utf8

RUN mkdir /docker-entrypoint-initdb.d

ENV PG_MAJOR 11
ENV PG_VERSION 11.16
ENV PG_SHA256 2dd9e111f0a5949ee7cacc065cea0fb21092929bae310ce05bf01b4ffc5103a5

RUN set -eux; \
 \
 wget -O postgresql.tar.bz2 "https://ftp.postgresql.org/pub/source/v$PG_VERSION/postgresql-$PG_VERSION.tar.bz2"; \
 echo "$PG_SHA256 *postgresql.tar.bz2" | sha256sum -c -; \
 mkdir -p /usr/src/postgresql; \
 tar \
  --extract \
  --file postgresql.tar.bz2 \
  --directory /usr/src/postgresql \
  --strip-components 1 \
 ; \
 rm postgresql.tar.bz2; \
 \
 apk add --no-cache --virtual .build-deps \
  bison \
  coreutils \
  dpkg-dev dpkg \
  flex \
  gcc \
  krb5-dev \
  libc-dev \
  libedit-dev \
  libxml2-dev \
  libxslt-dev \
  linux-headers \
  llvm-dev clang g++ \
  make \
  openldap-dev \
  openssl-dev \
  perl-dev \
  perl-ipc-run \
  perl-utils \
  python3-dev \
  tcl-dev \
  util-linux-dev \
  zlib-dev \
# https://www.postgresql.org/docs/10/static/release-10.html#id-1.11.6.9.5.13
  icu-dev \
 ; \
 \
 cd /usr/src/postgresql; \
# update "DEFAULT_PGSOCKET_DIR" to "/var/run/postgresql" (matching Debian)
# see https://anonscm.debian.org/git/pkg-postgresql/postgresql.git/tree/debian/patches/51-default-sockets-in-var.patch?id=8b539fcb3e093a521c095e70bdfa76887217b89f
 awk '$1 == "#define" && $2 == "DEFAULT_PGSOCKET_DIR" && $3 == "\"/tmp\"" { $3 = "\"/var/run/postgresql\""; print; next } { print }' src/include/pg_config_manual.h > src/include/pg_config_manual.h.new; \
 grep '/var/run/postgresql' src/include/pg_config_manual.h.new; \
 mv src/include/pg_config_manual.h.new src/include/pg_config_manual.h; \
 gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
# explicitly update autoconf config.guess and config.sub so they support more arches/libcs
 wget -O config/config.guess 'https://git.savannah.gnu.org/cgit/config.git/plain/config.guess?id=7d3d27baf8107b630586c962c057e22149653deb'; \
 wget -O config/config.sub 'https://git.savannah.gnu.org/cgit/config.git/plain/config.sub?id=7d3d27baf8107b630586c962c057e22149653deb'; \
# configure options taken from:
# https://anonscm.debian.org/cgit/pkg-postgresql/postgresql.git/tree/debian/rules?h=9.5
 ./configure \
  --build="$gnuArch" \
# "/usr/src/postgresql/src/backend/access/common/tupconvert.c:105: undefined reference to `libintl_gettext'"
#  --enable-nls \
  --enable-integer-datetimes \
  --enable-thread-safety \
  --enable-tap-tests \
# skip debugging info -- we want tiny size instead
#  --enable-debug \
  --disable-rpath \
  --with-uuid=e2fs \
  --with-gnu-ld \
  --with-pgport=5432 \
  --with-system-tzdata=/usr/share/zoneinfo \
  --prefix=/usr/local \
  --with-includes=/usr/local/include \
  --with-libraries=/usr/local/lib \
  --with-krb5 \
  --with-gssapi \
  --with-ldap \
  --with-tcl \
  --with-perl \
  --with-python \
#  --with-pam \
  --with-openssl \
  --with-libxml \
  --with-libxslt \
  --with-icu \
  --with-llvm \
 ; \
 make -j "$(nproc)" world; \
 make install-world; \
 make -C contrib install; \
 \
 runDeps="$( \
  scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
   | tr ',' '\n' \
   | sort -u \
   | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
# Remove plperl, plpython and pltcl dependencies by default to save image size
# To use the pl extensions, those have to be installed in a derived image
   | grep -v -e perl -e python -e tcl \
 )"; \
 apk add --no-cache --virtual .postgresql-rundeps \
  $runDeps \
  bash \
  su-exec \
  tzdata \
  zstd \
# https://wiki.alpinelinux.org/wiki/Release_Notes_for_Alpine_3.16.0#ICU_data_split
  icu-data-full \
 ; \
 apk del --no-network .build-deps; \
 cd /; \
 rm -rf \
  /usr/src/postgresql \
  /usr/local/share/doc \
  /usr/local/share/man \
 ; \
 \
 postgres --version

# make the sample config easier to munge (and "correct by default")
RUN set -eux; \
 cp -v /usr/local/share/postgresql/postgresql.conf.sample /usr/local/share/postgresql/postgresql.conf.sample.orig; \
 sed -ri "s!^#?(listen_addresses)\s*=\s*\S+.*!\1 = '*'!" /usr/local/share/postgresql/postgresql.conf.sample; \
 grep -F "listen_addresses = '*'" /usr/local/share/postgresql/postgresql.conf.sample

RUN mkdir -p /var/run/postgresql && chown -R postgres:postgres /var/run/postgresql && chmod 2777 /var/run/postgresql

ENV PGDATA /var/lib/postgresql/data
# this 777 will be replaced by 700 at runtime (allows semi-arbitrary "--user" values)
RUN mkdir -p "$PGDATA" && chown -R postgres:postgres "$PGDATA" && chmod 777 "$PGDATA"
VOLUME /var/lib/postgresql/data

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

# We set the default STOPSIGNAL to SIGINT, which corresponds to what PostgreSQL
# calls "Fast Shutdown mode" wherein new connections are disallowed and any
# in-progress transactions are aborted, allowing PostgreSQL to stop cleanly and
# flush tables to disk, which is the best compromise available to avoid data
# corruption.
#
# Users who know their applications do not keep open long-lived idle connections
# may way to use a value of SIGTERM instead, which corresponds to "Smart
# Shutdown mode" in which any existing sessions are allowed to finish and the
# server stops when all sessions are terminated.
#
# See https://www.postgresql.org/docs/12/server-shutdown.html for more details
# about available PostgreSQL server shutdown signals.
#
# See also https://www.postgresql.org/docs/12/server-start.html for further
# justification of this as the default value, namely that the example (and
# shipped) systemd service files use the "Fast Shutdown mode" for service
# termination.
#
STOPSIGNAL SIGINT
#
# An additional setting that is recommended for all users regardless of this
# value is the runtime "--stop-timeout" (or your orchestrator/runtime's
# equivalent) for controlling how long to wait between sending the defined
# STOPSIGNAL and sending SIGKILL (which is likely to cause data corruption).
#
# The default in most runtimes (such as Docker) is 10 seconds, and the
# documentation at https://www.postgresql.org/docs/12/server-start.html notes
# that even 90 seconds may not be long enough in many instances.

EXPOSE 5432
CMD ["postgres"]
