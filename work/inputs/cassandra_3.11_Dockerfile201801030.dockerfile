# vim:set ft=dockerfile:
FROM debian:jessie-backports

# explicitly set user/group IDs
RUN groupadd -r cassandra --gid=999 && useradd -r -g cassandra --uid=999 cassandra

# grab gosu for easy step-down from root
ENV GOSU_VERSION 1.10
RUN set -x \
 && apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
 && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
 && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
 && export GNUPGHOME="$(mktemp -d)" \
 && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
 && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
 && rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc \
 && chmod +x /usr/local/bin/gosu \
 && gosu nobody true \
 && apt-get purge -y --auto-remove ca-certificates wget

# solves warning: "jemalloc shared library could not be preloaded to speed up memory allocations"
RUN apt-get update && apt-get install -y --no-install-recommends libjemalloc1 && rm -rf /var/lib/apt/lists/*

# https://github.com/docker-library/cassandra/pull/98#issuecomment-280761137
RUN { \
  echo 'Package: openjdk-* ca-certificates-java'; \
  echo 'Pin: release n=*-backports'; \
  echo 'Pin-Priority: 990'; \
 } > /etc/apt/preferences.d/java-backports

# https://wiki.apache.org/cassandra/DebianPackaging#Adding_Repository_Keys
ENV GPG_KEYS \
# gpg: key 0353B12C: public key "T Jake Luciani <jake@apache.org>" imported
 514A2AD631A57A16DD0047EC749D6EEC0353B12C \
# gpg: key FE4B2BDA: public key "Michael Shuler <michael@pbandjelly.org>" imported
 A26E528B271F19B9E5D8E19EA278B781FE4B2BDA
RUN set -ex; \
 export GNUPGHOME="$(mktemp -d)"; \
 for key in $GPG_KEYS; do \
  gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
 done; \
 gpg --export $GPG_KEYS > /etc/apt/trusted.gpg.d/cassandra.gpg; \
 rm -r "$GNUPGHOME"; \
 apt-key list

ENV CASSANDRA_VERSION 3.11.1

RUN set -ex; \
 \
 dpkgArch="$(dpkg --print-architecture)"; \
 case "$dpkgArch" in \
  amd64|i386) \
# arches officialy included in upstream's repo metadata
   echo 'deb http://www.apache.org/dist/cassandra/debian 311x main' > /etc/apt/sources.list.d/cassandra.list; \
   apt-get update; \
   ;; \
  *) \
# we're on an architecture upstream doesn't include in their repo Architectures
# but their provided packages are "Architecture: all" so we can download them directly instead
   \
# save a list of installed packages so build deps can be removed cleanly
   savedAptMark="$(apt-mark showmanual)"; \
   \
# fetch a few build dependencies
   apt-get update; \
   apt-get install -y --no-install-recommends \
    wget ca-certificates \
    dpkg-dev \
   ; \
# we don't remove APT lists here because they get re-downloaded and removed later
   \
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
# (which is done after we install the built packages so we don't have to redownload any overlapping dependencies)
   apt-mark showmanual | xargs apt-mark auto > /dev/null; \
   apt-mark manual $savedAptMark; \
   \
# download the two "arch: all" packages we need
   tempDir="$(mktemp -d)"; \
   for pkg in cassandra cassandra-tools; do \
    deb="${pkg}_${CASSANDRA_VERSION}_all.deb"; \
    wget -O "$tempDir/$deb" "http://www.apache.org/dist/cassandra/debian/pool/main/c/cassandra/$deb"; \
   done; \
   \
# create a temporary local APT repo to install from (so that dependency resolution can be handled by APT, as it should be)
   ls -lAFh "$tempDir"; \
   ( cd "$tempDir" && dpkg-scanpackages . > Packages ); \
   grep '^Package: ' "$tempDir/Packages"; \
   echo "deb [ trusted=yes ] file://$tempDir ./" > /etc/apt/sources.list.d/temp.list; \
# work around the following APT issue by using "Acquire::GzipIndexes=false" (overriding "/etc/apt/apt.conf.d/docker-gzip-indexes")
#   Could not open file /var/lib/apt/lists/partial/_tmp_tmp.ODWljpQfkE_._Packages - open (13: Permission denied)
#   ...
#   E: Failed to fetch store:/var/lib/apt/lists/partial/_tmp_tmp.ODWljpQfkE_._Packages  Could not open file /var/lib/apt/lists/partial/_tmp_tmp.ODWljpQfkE_._Packages - open (13: Permission denied)
   apt-get -o Acquire::GzipIndexes=false update; \
   ;; \
 esac; \
 \
 apt-get install -y \
  cassandra="$CASSANDRA_VERSION" \
  cassandra-tools="$CASSANDRA_VERSION" \
 ; \
 \
 rm -rf /var/lib/apt/lists/*; \
 \
 if [ -n "$tempDir" ]; then \
# if we have leftovers from building, let's purge them (including extra, unnecessary build deps)
  apt-get purge -y --auto-remove; \
  rm -rf "$tempDir" /etc/apt/sources.list.d/temp.list; \
 fi

ENV CASSANDRA_CONFIG /etc/cassandra

RUN set -ex; \
 \
 dpkgArch="$(dpkg --print-architecture)"; \
 case "$dpkgArch" in \
  ppc64el) \
# https://issues.apache.org/jira/browse/CASSANDRA-13345
# "The stack size specified is too small, Specify at least 328k"
   if grep -q -- '^-Xss' "$CASSANDRA_CONFIG/jvm.options"; then \
# 3.11+ (jvm.options)
    grep -- '^-Xss256k$' "$CASSANDRA_CONFIG/jvm.options"; \
    sed -ri 's/^-Xss256k$/-Xss512k/' "$CASSANDRA_CONFIG/jvm.options"; \
    grep -- '^-Xss512k$' "$CASSANDRA_CONFIG/jvm.options"; \
   elif grep -q -- '-Xss256k' "$CASSANDRA_CONFIG/cassandra-env.sh"; then \
# 3.0 (cassandra-env.sh)
    sed -ri 's/-Xss256k/-Xss512k/g' "$CASSANDRA_CONFIG/cassandra-env.sh"; \
    grep -- '-Xss512k' "$CASSANDRA_CONFIG/cassandra-env.sh"; \
   fi; \
   ;; \
 esac; \
 \
# https://issues.apache.org/jira/browse/CASSANDRA-11661
 sed -ri 's/^(JVM_PATCH_VERSION)=.*/\1=25/' "$CASSANDRA_CONFIG/cassandra-env.sh"

COPY docker-entrypoint.sh /usr/local/bin/
RUN ln -s usr/local/bin/docker-entrypoint.sh /docker-entrypoint.sh # backwards compat
ENTRYPOINT ["docker-entrypoint.sh"]

RUN mkdir -p /var/lib/cassandra "$CASSANDRA_CONFIG" \
 && chown -R cassandra:cassandra /var/lib/cassandra "$CASSANDRA_CONFIG" \
 && chmod 777 /var/lib/cassandra "$CASSANDRA_CONFIG"
VOLUME /var/lib/cassandra

# 7000: intra-node communication
# 7001: TLS intra-node communication
# 7199: JMX
# 9042: CQL
# 9160: thrift service
EXPOSE 7000 7001 7199 9042 9160
CMD ["cassandra", "-f"]
