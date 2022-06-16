#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

# from https://downloads.joomla.org/technical-requirements
FROM php:7.4-apache
LABEL maintainer="Llewellyn van der Merwe <llewellyn.van-der-merwe@community.joomla.org> (@Llewellynvdm), Harald Leithner <harald.leithner@community.joomla.org> (@HLeithner)"

# Disable remote database security requirements.
ENV JOOMLA_INSTALLATION_DISABLE_LOCALHOST_CHECK=1
# Enable Apache Rewrite Module
RUN a2enmod rewrite
# Install the PHP extensions
RUN set -ex; \
 \
 savedAptMark="$(apt-mark showmanual)"; \
 \
 apt-get update; \
 apt-get install -y --no-install-recommends \
  libbz2-dev \
  libgmp-dev \
  libicu-dev \
  libjpeg-dev \
  libldap2-dev \
  libmemcached-dev \
  libpng-dev \
  libpq-dev \
  libzip-dev \
 ; \
 \
 docker-php-ext-configure gd --with-jpeg; \
 debMultiarch="$(dpkg-architecture --query DEB_BUILD_MULTIARCH)"; \
 docker-php-ext-configure ldap --with-libdir="lib/$debMultiarch"; \
 docker-php-ext-install -j "$(nproc)" \
  bz2 \
  gd \
  gmp \
  intl \
  ldap \
  mysqli \
  pdo_mysql \
  pdo_pgsql \
  pgsql \
  zip \
 ; \
 \
# pecl will claim success even if one install fails, so we need to perform each install separately
 pecl install APCu-5.1.21; \
 pecl install memcached-3.2.0; \
 pecl install redis-5.3.7; \
 \
 docker-php-ext-enable \
  apcu \
  memcached \
  redis \
 ; \
 rm -r /tmp/pear; \
 \
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
 apt-mark auto '.*' > /dev/null; \
 apt-mark manual $savedAptMark; \
 ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
  | awk '/=>/ { print $3 }' \
  | sort -u \
  | xargs -r dpkg-query -S \
  | cut -d: -f1 \
  | sort -u \
  | xargs -rt apt-mark manual; \
 \
 apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
 rm -rf /var/lib/apt/lists/*

VOLUME /var/www/html

# Define Joomla version and expected SHA512 signature
ENV JOOMLA_VERSION 4.1.4
ENV JOOMLA_SHA512 a9ffd64d8320d3df2f58df924b750f4b75a15eac194b4a8ef98671208ad2ca8a09a3ea6d55cce51eceded89eae7d6252ba64057b3e12ef88bc75a43d7ee6d70d

# Download package and extract to web volume
RUN set -ex; \
 curl -o joomla.tar.bz2 -SL https://github.com/joomla/joomla-cms/releases/download/${JOOMLA_VERSION}/Joomla_${JOOMLA_VERSION}-Stable-Full_Package.tar.bz2; \
 echo "$JOOMLA_SHA512 *joomla.tar.bz2" | sha512sum -c -; \
 mkdir /usr/src/joomla; \
 tar -xf joomla.tar.bz2 -C /usr/src/joomla; \
 rm joomla.tar.bz2; \
 chown -R www-data:www-data /usr/src/joomla

# Copy init scripts and custom .htaccess
COPY docker-entrypoint.sh /entrypoint.sh
COPY makedb.php /makedb.php

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]

# vim:set ft=dockerfile:
