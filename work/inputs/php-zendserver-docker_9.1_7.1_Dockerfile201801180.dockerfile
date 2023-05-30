# Zend Server
#
# Version 9.1.2+b144

FROM ubuntu:14.04

#Import repos.zend.com's public key
RUN apt-key adv --keyserver pgp.mit.edu --recv-key 799058698E65316A2E7A4FF42EAE1437F7D2C623
#Add Zend Server's repository
RUN echo "deb http://repos.zend.com/zend-server/9.1/deb_apache2.4 server non-free" >> /etc/apt/sources.list.d/zend-server.list
RUN apt-get update && \
    apt-get install -y \
    curl libmysqlclient18 unzip git zend-server-php-7.1=9.1.2+b144 && \
    apt-get clean && \
    /usr/local/zend/bin/zendctl.sh stop 

#Set default license
COPY ./zend.lic /etc/

#Make apache drop the HTTP_PROXY header to fix CVE-2016-5385, CVE-2016-5387
COPY ./drop-http-proxy-header.conf /etc/apache2/conf-available
RUN  /usr/sbin/a2enconf drop-http-proxy-header
RUN /usr/sbin/a2enmod headers

# "zs-init" is a standard Zend Server cloud initialization package.
# It has minor tweaks for use within Docker which can be found at https://github.com/zendtech/zs-init/treye/docker
ENV ZS_INIT_VERSION 0.3
ENV ZS_INIT_SHA256 e8d441d8503808e9fc0fafc762b2cb80d4a6e68b94fede0fe41efdeac10800cb
RUN curl -fSL -o zs-init.tar.gz "http://repos.zend.com/zs-init/zs-init-docker-${ZS_INIT_VERSION}.tar.gz" \
    && echo "${ZS_INIT_SHA256} *zs-init.tar.gz" | sha256sum -c - \
    && mkdir /usr/local/zs-init \
    && tar xzf zs-init.tar.gz --strip-components=1 -C /usr/local/zs-init \
    && rm zs-init.tar.gz

#Install composer and dependencies for zs-init
WORKDIR /usr/local/zs-init
RUN /usr/local/zend/bin/php -r "readfile('https://getcomposer.org/installer');" | /usr/local/zend/bin/php
RUN /usr/local/zend/bin/php composer.phar update

COPY ./scripts /usr/local/bin
#Copy Zray docker plugin
#TODO: Integrate Zray docker plugin into Zend Server
COPY ./Zray /usr/local/zend/var/plugins/

RUN rm /var/www/html/index.html
COPY ./app /var/www/html

EXPOSE 80
EXPOSE 443
EXPOSE 10081
EXPOSE 10082

WORKDIR /var/www/html

CMD ["/usr/local/bin/run"]