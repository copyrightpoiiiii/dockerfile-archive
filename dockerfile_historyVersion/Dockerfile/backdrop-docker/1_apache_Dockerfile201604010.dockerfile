# from https://backdropcms.org/requirements
FROM php:5.6-apache

RUN a2enmod rewrite

# install the PHP extensions we need
RUN apt-get update && apt-get install -y libpng12-dev libjpeg-dev libpq-dev \
 && rm -rf /var/lib/apt/lists/* \
 && docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
 && docker-php-ext-install gd mbstring pdo pdo_mysql pdo_pgsql zip

WORKDIR /var/www/html

# https://github.com/backdrop/backdrop/releases
ENV BACKDROP_VERSION 1.3.4
ENV BACKDROP_MD5 1bcfacab25cd71743ad87bdf391a53c8

RUN curl -fSL "https://github.com/backdrop/backdrop/archive/${BACKDROP_VERSION}.tar.gz" -o backdrop.tar.gz \
  && echo "${BACKDROP_MD5} *backdrop.tar.gz" | md5sum -c - \
  && tar -xz --strip-components=1 -f backdrop.tar.gz \
  && rm backdrop.tar.gz \
  && chown -R www-data:www-data sites
