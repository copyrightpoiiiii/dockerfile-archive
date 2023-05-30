# from https://backdropcms.org/requirements
FROM php:7.4-fpm

# install the PHP extensions we need
RUN apt-get update && apt-get install -y libzip-dev libonig-dev libpng-dev libjpeg-dev libpq-dev \
 && rm -rf /var/lib/apt/lists/* \
 && docker-php-ext-configure gd --with-jpeg=/usr \
 && docker-php-ext-install gd mbstring pdo pdo_mysql pdo_pgsql zip

WORKDIR /var/www/html

# https://github.com/backdrop/backdrop/releases
ENV BACKDROP_VERSION 1.21.3
ENV BACKDROP_MD5 a93fe043630a617f6ae0977aaae3e919

RUN curl -fSL "https://github.com/backdrop/backdrop/archive/${BACKDROP_VERSION}.tar.gz" -o backdrop.tar.gz \
 && echo "${BACKDROP_MD5} *backdrop.tar.gz" | md5sum -c - \
 && tar -xz --strip-components=1 -f backdrop.tar.gz \
 && rm backdrop.tar.gz \
 && chown -R www-data:www-data sites

# Add custom entrypoint to set BACKDROP_SETTINGS correctly
COPY docker-entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]
