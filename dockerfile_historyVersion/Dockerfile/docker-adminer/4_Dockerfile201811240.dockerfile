FROM php:7.2-alpine

RUN echo "upload_max_filesize = 128M" >> /usr/local/etc/php/conf.d/0-upload_large_dumps.ini \
&& echo "post_max_size = 128M" >> /usr/local/etc/php/conf.d/0-upload_large_dumps.ini \
&& echo "memory_limit = 1G" >> /usr/local/etc/php/conf.d/0-upload_large_dumps.ini \
&& echo "max_execution_time = 600" >> /usr/local/etc/php/conf.d/0-upload_large_dumps.ini \
&& echo "max_input_vars = 5000" >> /usr/local/etc/php/conf.d/0-upload_large_dumps.ini

STOPSIGNAL SIGINT

RUN addgroup -S adminer \
&& adduser -S -G adminer adminer \
&& mkdir -p /var/www/html \
&& mkdir -p /var/www/html/plugins-enabled \
&& chown -R adminer:adminer /var/www/html

WORKDIR /var/www/html

RUN apk add --no-cache libpq

RUN set -x \
&& apk add --no-cache --virtual .build-deps \
 postgresql-dev \
 sqlite-dev \
&& docker-php-ext-install pdo_mysql pdo_pgsql pdo_sqlite \
&& apk del .build-deps

COPY *.php /var/www/html/

ENV ADMINER_VERSION 4.7.0
ENV ADMINER_DOWNLOAD_SHA256 e71766f7b54f87b6b45d0a56601301eb14a031f80bbc511dce5b40b7f27902e3
ENV ADMINER_SRC_DOWNLOAD_SHA256 0a7bbe9d07946c79bcd4d9f73f13dc58b018dc681c3953ea7fa9a59e0ee9eed3

RUN set -x \
&& curl -fsSL https://github.com/vrana/adminer/releases/download/v$ADMINER_VERSION/adminer-$ADMINER_VERSION.php -o adminer.php \
&& echo "$ADMINER_DOWNLOAD_SHA256  adminer.php" |sha256sum -c - \
&& curl -fsSL https://github.com/vrana/adminer/archive/v$ADMINER_VERSION.tar.gz -o source.tar.gz \
&& echo "$ADMINER_SRC_DOWNLOAD_SHA256  source.tar.gz" |sha256sum -c - \
&& tar xzf source.tar.gz --strip-components=1 "adminer-$ADMINER_VERSION/designs/" "adminer-$ADMINER_VERSION/plugins/" \
&& rm source.tar.gz

COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT [ "entrypoint.sh", "docker-php-entrypoint" ]

USER adminer
CMD [ "php", "-S", "[::]:8080", "-t", "/var/www/html" ]

EXPOSE 8080
