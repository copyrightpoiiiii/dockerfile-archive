FROM node:18-alpine

WORKDIR /usr/app/src

ADD package.json package.json
RUN yarn install --frozen-lockfile --production --silent

ADD duo_api.js duo_api.js

EXPOSE 3000

CMD ["node", "duo_api.js"]
