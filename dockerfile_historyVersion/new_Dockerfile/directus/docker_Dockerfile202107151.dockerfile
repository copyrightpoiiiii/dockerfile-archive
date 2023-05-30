ARG NODE_VERSION=16-alpine

FROM node:${NODE_VERSION} as builder

WORKDIR /directus
COPY /dist .
RUN npm i --only=production --no-package-lock
RUN rm *.tgz

# Directus image
FROM node:16-alpine

ARG VERSION
ARG REPOSITORY=directus/directus

LABEL directus.version="${VERSION}"

# Default environment variables
# (see https://docs.directus.io/reference/environment-variables/)
ENV \
  DB_CLIENT="sqlite3" \
  DB_FILENAME="/directus/database/database.sqlite" \
  EXTENSIONS_PATH="/directus/extensions" \
  STORAGE_LOCAL_ROOT="/directus/uploads"

RUN \
  # Upgrade system and install 'ssmtp' to be able to send mails
  apk upgrade --no-cache && apk add --no-cache \
  ssmtp \
  # Create directory for Directus with corresponding ownership
  # (can be omitted on newer Docker versions since WORKDIR below will do the same)
  && mkdir /directus && chown node:node /directus

# Switch to user 'node' and directory '/directus'
USER node
WORKDIR /directus

COPY --from=builder --chown=node:node /directus .

RUN \
  # Create data directories
  mkdir -p \
    database \
    extensions \
    uploads

# Expose data directories as volumes
VOLUME \
  /directus/database \
  /directus/extensions \
  /directus/uploads

EXPOSE 8055
CMD npx directus bootstrap && npx directus start
