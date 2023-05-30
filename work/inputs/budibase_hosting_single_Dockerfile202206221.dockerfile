FROM node:14-slim as build

# install node-gyp dependencies
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends apt-utils g++ make python

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

ARG TARGETARCH amd64

COPY --from=build /app /app
COPY --from=build /worker /worker

ENV \
  APP_PORT=4001 \
  ARCHITECTURE=amd \
  BUDIBASE_ENVIRONMENT=PRODUCTION \
  CLUSTER_PORT=80 \
  COUCHDB_PASSWORD=budibase \
  COUCHDB_USER=budibase \
  COUCH_DB_URL=http://budibase:budibase@localhost:5984 \
  CUSTOM_DOMAIN=budi001.custom.com \
  DEPLOYMENT_ENVIRONMENT=docker \
  INTERNAL_API_KEY=budibase \
  JWT_SECRET=testsecret \
  MINIO_ACCESS_KEY=budibase \
  MINIO_SECRET_KEY=budibase \
  MINIO_URL=http://localhost:9000 \
  POSTHOG_TOKEN=phc_fg5I3nDOf6oJVMHSaycEhpPdlgS8rzXG2r6F2IpxCHS \
  REDIS_PASSWORD=budibase \
  REDIS_URL=localhost:6379 \
  SELF_HOSTED=1 \
  WORKER_PORT=4002 \
  WORKER_URL=http://localhost:4002

# install base dependencies
RUN apt-get update && \
  apt-get install -y software-properties-common wget nginx && \
  apt-add-repository 'deb http://security.debian.org/debian-security stretch/updates main' && \
  apt-get update

# install other dependencies, nodejs, oracle requirements, jdk8, redis, nginx
WORKDIR /nodejs
RUN curl -sL https://deb.nodesource.com/setup_16.x -o /tmp/nodesource_setup.sh && \
  bash /tmp/nodesource_setup.sh && \
  apt-get install -y libaio1 nodejs nginx openjdk-8-jdk redis-server unzip && \
  npm install --global yarn pm2

# setup nginx
ADD hosting/single/nginx.conf /etc/nginx
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
ADD hosting/single/clouseau ./bin/
ADD hosting/single/log4j.properties hosting/single/clouseau.ini ./
RUN chmod +x ./bin/clouseau

# setup CouchDB
WORKDIR /opt/couchdb
ADD hosting/single/vm.args ./etc/

# setup minio
WORKDIR /minio
ADD scripts/install-minio.sh ./install.sh
RUN chmod +x install.sh && ./install.sh

# setup runner file
WORKDIR /
ADD hosting/single/runner.sh .
RUN chmod +x ./runner.sh
ADD hosting/scripts/healthcheck.sh .
RUN chmod +x ./healthcheck.sh

# cleanup cache
RUN yarn cache clean -f

EXPOSE 80
EXPOSE 443
VOLUME /opt/couchdb/data
VOLUME /minio

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
