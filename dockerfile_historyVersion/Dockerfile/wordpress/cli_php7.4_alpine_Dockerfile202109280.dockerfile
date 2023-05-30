#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM php:7.4-alpine

# install wp-cli dependencies
RUN apk add --no-cache \
# bash is needed for 'wp shell': https://github.com/wp-cli/shell-command/blob/b8dafcc2a2eba5732fdee70be077675a302848e9/src/WP_CLI/REPL.php#L104
  bash \
  less \
  mysql-client

RUN set -ex; \
 mkdir -p /var/www/html; \
 chown -R www-data:www-data /var/www/html
WORKDIR /var/www/html

# install the PHP extensions we need (https://make.wordpress.org/hosting/handbook/handbook/server-environment/#php-extensions)
RUN set -ex; \
 \
 apk add --no-cache --virtual .build-deps \
  $PHPIZE_DEPS \
  freetype-dev \
  imagemagick-dev \
  libjpeg-turbo-dev \
  libpng-dev \
  libwebp-dev \
  libzip-dev \
 ; \
 \
 docker-php-ext-configure gd \
  --with-freetype \
  --with-jpeg \
  --with-webp \
 ; \
 docker-php-ext-install -j "$(nproc)" \
  bcmath \
  exif \
  gd \
  mysqli \
  zip \
 ; \
# WARNING: imagick is likely not supported on Alpine: https://github.com/Imagick/imagick/issues/328
# https://pecl.php.net/package/imagick
 pecl install imagick-3.5.0; \
 docker-php-ext-enable imagick; \
 rm -r /tmp/pear; \
 \
 runDeps="$( \
  scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
   | tr ',' '\n' \
   | sort -u \
   | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
 )"; \
 apk add --no-network --virtual .wordpress-phpexts-rundeps $runDeps; \
 apk del --no-network .build-deps

# set recommended PHP.ini settings
# excluding opcache due https://github.com/docker-library/wordpress/issues/407
# https://wordpress.org/support/article/editing-wp-config-php/#configure-error-logging
RUN { \
# https://www.php.net/manual/en/errorfunc.constants.php
# https://github.com/docker-library/wordpress/issues/420#issuecomment-517839670
  echo 'error_reporting = E_ERROR | E_WARNING | E_PARSE | E_CORE_ERROR | E_CORE_WARNING | E_COMPILE_ERROR | E_COMPILE_WARNING | E_RECOVERABLE_ERROR'; \
  echo 'display_errors = Off'; \
  echo 'display_startup_errors = Off'; \
  echo 'log_errors = On'; \
  echo 'error_log = /dev/stderr'; \
  echo 'log_errors_max_len = 1024'; \
  echo 'ignore_repeated_errors = On'; \
  echo 'ignore_repeated_source = Off'; \
  echo 'html_errors = Off'; \
 } > /usr/local/etc/php/conf.d/error-logging.ini

# https://make.wordpress.org/cli/2018/05/31/gpg-signature-change/
# pub   rsa2048 2018-05-31 [SC]
#       63AF 7AA1 5067 C056 16FD  DD88 A3A2 E8F2 26F0 BC06
# uid           [ unknown] WP-CLI Releases <releases@wp-cli.org>
# sub   rsa2048 2018-05-31 [E]
ENV WORDPRESS_CLI_GPG_KEY 63AF7AA15067C05616FDDD88A3A2E8F226F0BC06

ENV WORDPRESS_CLI_VERSION 2.5.0
ENV WORDPRESS_CLI_SHA512 08dd9035fda1d529807380d5b757839e2809e289eb1a698fe33e7e21a1431d3f77c551c2b2db5adc55083d5075ea4137407994111890f765e790a97e6d9ca7af

RUN set -ex; \
 \
 apk add --no-cache --virtual .fetch-deps \
  gnupg \
 ; \
 \
 curl -o /usr/local/bin/wp.gpg -fL "https://github.com/wp-cli/wp-cli/releases/download/v${WORDPRESS_CLI_VERSION}/wp-cli-${WORDPRESS_CLI_VERSION}.phar.gpg"; \
 \
 GNUPGHOME="$(mktemp -d)"; export GNUPGHOME; \
 gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$WORDPRESS_CLI_GPG_KEY"; \
 gpg --batch --decrypt --output /usr/local/bin/wp /usr/local/bin/wp.gpg; \
 gpgconf --kill all; \
 rm -rf "$GNUPGHOME" /usr/local/bin/wp.gpg; unset GNUPGHOME; \
 \
 echo "$WORDPRESS_CLI_SHA512 */usr/local/bin/wp" | sha512sum -c -; \
 chmod +x /usr/local/bin/wp; \
 \
 apk del --no-network .fetch-deps; \
 \
 wp --allow-root --version

VOLUME /var/www/html

COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]
USER www-data
CMD ["wp", "shell"]