# This file was auto-generated, do not edit it directly.
# Instead run bin/update_build_scripts from
# https://github.com/sharelatex/sharelatex-dev-environment

FROM node:14.18.1 as base

WORKDIR /overleaf/services/contacts

FROM base as app

COPY services/contacts/package*.json /overleaf/services/contacts/

RUN npm ci --quiet

COPY services/contacts /overleaf/services/contacts

FROM app
USER node

CMD ["node", "--expose-gc", "app.js"]