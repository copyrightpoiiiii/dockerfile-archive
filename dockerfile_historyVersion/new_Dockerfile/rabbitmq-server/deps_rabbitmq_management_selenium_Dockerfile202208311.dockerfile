# syntax=docker/dockerfile:1
FROM node:14.15.4 as base

WORKDIR /code

COPY package.json package.json

FROM base as test
RUN npm install
ENTRYPOINT [ "./node_modules/.bin/mocha", "--recursive", "--trace-warnings", "--timeout 35000"]