FROM node:14-slim

RUN apt-get update

LABEL com.centurylinklabs.watchtower.lifecycle.pre-check="scripts/watchtower-hooks/pre-check.sh"
LABEL com.centurylinklabs.watchtower.lifecycle.pre-update="scripts/watchtower-hooks/pre-update.sh"
LABEL com.centurylinklabs.watchtower.lifecycle.post-update="scripts/watchtower-hooks/post-update.sh"
LABEL com.centurylinklabs.watchtower.lifecycle.post-check="scripts/watchtower-hooks/post-check.sh"

WORKDIR /app

ENV PORT=4001
ENV COUCH_DB_URL=https://couchdb.budi.live:5984
ENV BUDIBASE_ENVIRONMENT=PRODUCTION

# copy files and install dependencies
COPY . ./
# handle node-gyp
RUN apk add --no-cache --virtual .gyp python3 make g++ \
    && yarn && apk del .gyp
RUN yarn global add pm2
RUN yarn build

# Install client for oracle datasource
RUN apt-get install unzip libaio1
RUN /bin/bash -e scripts/integrations/oracle/instantclient/linux/x86-64/install.sh 

EXPOSE 4001

# have to add node environment production after install
# due to this causing yarn to stop installing dev dependencies
# which are actually needed to get this environment up and running
ENV NODE_ENV=production
ENV CLUSTER_MODE=${CLUSTER_MODE}
CMD ["./docker_run.sh"]