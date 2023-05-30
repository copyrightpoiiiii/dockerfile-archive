#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh".
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM python:3.10-slim-bullseye

# runtime dependencies
RUN set -eux; \
 groupadd -g 1000 satosa; \
 useradd -g 1000 -u 1000 satosa; \
 apt-get update; \
 apt-get install -y --no-install-recommends \
  jq \
  libxml2-utils \
  xmlsec1 \
 ; \
 rm -rf /var/lib/apt/lists/*; \
 pip install --no-cache-dir \
  yq \
 ;

ENV SATOSA_VERSION 8.1.1
RUN set -eux; \
 savedAptMark="$(apt-mark showmanual)"; \
 apt-get update; \
 apt-get install -y --no-install-recommends \
  dpkg-dev \
  gcc \
  gnupg dirmngr \
  libbluetooth-dev \
  libbz2-dev \
  libc6-dev \
  libexpat1-dev \
  libffi-dev \
  libgdbm-dev \
  liblzma-dev \
  libncursesw5-dev \
  libreadline-dev \
  libsqlite3-dev \
  libssl-dev \
  make \
  tk-dev \
  uuid-dev \
  wget \
  xz-utils \
  zlib1g-dev \
 ; \
 pip install --no-cache-dir \
  satosa==${SATOSA_VERSION} \
 ; \
 apt-mark auto '.*' > /dev/null; \
 [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark > /dev/null; \
 apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
 rm -rf /var/lib/apt/lists/*; \
 mkdir /etc/satosa; \
 chown -R satosa:satosa /etc/satosa

# example configuration
RUN set -eux; \
 python -c 'import urllib.request; urllib.request.urlretrieve("https://github.com/IdentityPython/SATOSA/archive/refs/tags/v'${SATOSA_VERSION%%[a-z]*}'.tar.gz","/tmp/satosa.tgz")'; \
 mkdir /usr/share/satosa; \
 tar --extract --directory /usr/share/satosa --strip-components=1 --file /tmp/satosa.tgz SATOSA-${SATOSA_VERSION%%[a-z]*}/example/; \
 rm /tmp/satosa.tgz

WORKDIR /etc/satosa

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod 0755 /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 8080
USER satosa:satosa
CMD ["gunicorn","-b0.0.0.0:8080","satosa.wsgi:app"]
