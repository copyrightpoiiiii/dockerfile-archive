# Zend Server
#
# Version 9.1.2+b144

FROM ubuntu:14.04

RUN apt-key adv --keyserver pgp.mit.edu --recv-key 799058698E65316A2E7A4FF42EAE1437F7D2C623
RUN echo "deb http://repos.zend.com/zend-server/9.1/deb_apache2.4 server non-free" >> /etc/apt/sources.list.d/zend-server.list
RUN rm -f /var/lib/apt/lists/*
RUN apt-get clean && apt-get update && apt-get install -y curl && curl http://repos.zend.com/zend.key | apt-key add - ; apt-get update
RUN apt-get install -y libmysqlclient18 unzip git zend-server-php-7.1=9.1.2+b144 && /usr/local/zend/bin/zendctl.sh stop 

#Copy 
COPY ./zend-trial310618.lic /etc/

#Temporarily copy license file for use on container first run.
COPY ./zend-trial310618.lic /var/zend.lic.1

#Make apache drop the HTTP_PROXY header to fix CVE-2016-5385, CVE-2016-5387
COPY ./drop-http-proxy-header.conf /etc/apache2/conf-available
RUN  /usr/sbin/a2enconf drop-http-proxy-header
RUN /usr/sbin/a2enmod headers

# "zs-init" is a standard Zend Server cloud initialization package.
# It has minor tweaks for use within Docker which can be found at https://github.com/zendtech/zs-init/tree/docker
ENV ZS_INIT_VERSION 0.3
ENV ZS_INIT_SHA256 e8d441d8503808e9fc0fafc762b2cb80d4a6e68b94fede0fe41efdeac10800cb
RUN curl -fSL -o zs-init.tar.gz "http://repos.zend.com/zs-init/zs-init-docker-${ZS_INIT_VERSION}.tar.gz" \
    && echo "${ZS_INIT_SHA256} *zs-init.tar.gz" | sha256sum -c - \
    && mkdir /usr/local/zs-init \
    && tar xzf zs-init.tar.gz --strip-components=1 -C /usr/local/zs-init \
    && rm zs-init.tar.gz

WORKDIR /usr/local/zs-init
RUN find / -name zend.lic
RUN /usr/local/zend/bin/php -r "readfile('https://getcomposer.org/installer');" | /usr/local/zend/bin/php
RUN /usr/local/zend/bin/php composer.phar update

COPY ./scripts /usr/local/bin
COPY ./Zray /usr/local/zend/var/plugins/

RUN rm /var/www/html/index.html
COPY ./app /var/www/html

EXPOSE 80
EXPOSE 443
EXPOSE 10081
EXPOSE 10082

WORKDIR /var/www/html

CMD ["/usr/local/bin/run"]
