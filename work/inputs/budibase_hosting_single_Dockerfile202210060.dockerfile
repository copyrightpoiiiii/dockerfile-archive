FROM node:14-slim as build

# install node-gyp dependencies
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends apt-utils cron g++ make python

# add pin script
WORKDIR /
ADD scripts/pinVersions.js scripts/cleanup.sh ./
RUN chmod +x /cleanup.sh

# build server
WORKDIR /app
ADD packages/server .
RUN node /pinVersions.js && yarn && yarn build && /cleanup.sh

# build worker
WORKDIR /worker
ADD packages/worker .
RUN node /pinVersions.js && yarn && yarn build && /cleanup.sh

FROM couchdb:3.2.1
ARG TARGETARCH
ENV TARGETARCH $TARGETARCH
#TARGETBUILD can be set to single (for single docker image) or aas (for azure app service)
# e.g. docker build --build-arg TARGETBUILD=aas ....
ARG TARGETBUILD=single
ENV TARGETBUILD $TARGETBUILD

COPY --from=build /app /app
COPY --from=build /worker /worker

# ENV CUSTOM_DOMAIN=budi001.custom.com \
#  See runner.sh for Env Vars
# These secret env variables are generated by the runner at startup
# their values can be overriden by the user, they will be written
# to the .env file in the /data directory for use later on
#  REDIS_PASSWORD=budibase \
#  COUCHDB_PASSWORD=budibase \
#  COUCHDB_USER=budibase \
#  COUCH_DB_URL=http://budibase:budibase@localhost:5984 \
#  INTERNAL_API_KEY=budibase \
#  JWT_SECRET=testsecret \
#  MINIO_ACCESS_KEY=budibase \
#  MINIO_SECRET_KEY=budibase \

# install base dependencies
RUN apt-get update && \
  apt-get install -y software-properties-common wget nginx uuid-runtime && \
  apt-add-repository 'deb http://security.debian.org/debian-security stretch/updates main' && \
  apt-get update

# install other dependencies, nodejs, oracle requirements, jdk8, redis, nginx
WORKDIR /nodejs
RUN curl -sL https://deb.nodesource.com/setup_16.x -o /tmp/nodesource_setup.sh && \
  bash /tmp/nodesource_setup.sh && \
  apt-get install -y libaio1 nodejs nginx openjdk-8-jdk redis-server unzip && \
  npm install --global yarn pm2

# setup nginx
ADD hosting/single/nginx/nginx.conf /etc/nginx
ADD hosting/single/nginx/nginx-default-site.conf /etc/nginx/sites-enabled/default
RUN mkdir -p /var/log/nginx && \
  touch /var/log/nginx/error.log && \
  touch /var/run/nginx.pid

WORKDIR /
RUN mkdir -p scripts/integrations/oracle
ADD packages/server/scripts/integrations/oracle scripts/integrations/oracle
RUN /bin/bash -e ./scripts/integrations/oracle/instantclient/linux/install.sh

# setup clouseau
WORKDIR /
RUN wget https://github.com/cloudant-labs/clouseau/releases/download/2.21.0/clouseau-2.21.0-dist.zip && \
  unzip clouseau-2.21.0-dist.zip && \
  mv clouseau-2.21.0 /opt/clouseau && \
  rm clouseau-2.21.0-dist.zip

WORKDIR /opt/clouseau
RUN mkdir ./bin
ADD hosting/single/clouseau/clouseau ./bin/
ADD hosting/single/clouseau/log4j.properties hosting/single/clouseau/clouseau.ini ./
RUN chmod +x ./bin/clouseau

# setup CouchDB
WORKDIR /opt/couchdb
ADD hosting/single/couch/vm.args hosting/single/couch/local.ini ./etc/

# setup minio
WORKDIR /minio
ADD scripts/install-minio.sh ./install.sh
RUN chmod +x install.sh && ./install.sh

# setup runner file
WORKDIR /
ADD hosting/single/runner.sh .
RUN chmod +x ./runner.sh
ADD hosting/single/healthcheck.sh .
RUN chmod +x ./healthcheck.sh

ADD hosting/scripts/build-target-paths.sh .
RUN chmod +x ./build-target-paths.sh

# Script below sets the path for storing data based on $DATA_DIR
# For Azure App Service install SSH & point data locations to /home
ADD hosting/single/ssh/sshd_config /etc/
ADD hosting/single/ssh/ssh_setup.sh /tmp
RUN /build-target-paths.sh

# cleanup cache
RUN yarn cache clean -f

EXPOSE 80
EXPOSE 443
# Expose port 2222 for SSH on Azure App Service build
EXPOSE 2222
VOLUME /data

#  setup letsencrypt certificate
RUN apt-get install -y certbot python3-certbot-nginx
ADD hosting/letsencrypt /app/letsencrypt
RUN chmod +x /app/letsencrypt/certificate-request.sh /app/letsencrypt/certificate-renew.sh
# Remove cached files
RUN rm -rf \
  /root/.cache \
  /root/.npm \
  /root/.pip \
  /usr/local/share/doc \
  /usr/share/doc \
  /usr/share/man \
  /var/lib/apt/lists/* \
  /tmp/*

HEALTHCHECK --interval=15s --timeout=15s --start-period=45s CMD "/healthcheck.sh"

# must set this just before running
ENV NODE_ENV=production
WORKDIR /

CMD ["./runner.sh"]
