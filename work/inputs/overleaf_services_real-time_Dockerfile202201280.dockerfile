# This file was auto-generated, do not edit it directly.
# Instead run bin/update_build_scripts from
# https://github.com/sharelatex/sharelatex-dev-environment

FROM node:14.18.3 as base

WORKDIR /overleaf/services/real-time

FROM base as app

COPY services/real-time/package*.json /overleaf/services/real-time/

RUN npm ci --quiet

COPY services/real-time /overleaf/services/real-time

FROM app
USER node

CMD ["node", "--expose-gc", "app.js"]
