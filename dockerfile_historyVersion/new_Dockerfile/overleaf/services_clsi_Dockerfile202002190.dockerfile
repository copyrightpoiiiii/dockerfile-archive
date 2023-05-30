# This file was auto-generated, do not edit it directly.
# Instead run bin/update_build_scripts from
# https://github.com/sharelatex/sharelatex-dev-environment
# Version: 1.3.5

FROM node:10.19.0 as base

WORKDIR /app
COPY install_deps.sh /app
RUN chmod 0755 ./install_deps.sh && ./install_deps.sh
ENTRYPOINT ["/bin/sh", "entrypoint.sh"]
COPY entrypoint.sh /app

FROM base as app

#wildcard as some files may not be in all repos
COPY package*.json npm-shrink*.json /app/

RUN npm install --quiet

COPY . /app



FROM base

COPY --from=app /app /app

CMD ["node", "--expose-gc", "app.js"]
