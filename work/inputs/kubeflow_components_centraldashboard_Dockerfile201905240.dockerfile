FROM node:10

WORKDIR /centraldashboard

COPY app/ ./app
COPY types/ ./types
COPY public/ ./public
COPY webpack.config.js *.json .nycrc ./

ARG kubeflowversion
ARG commit
ENV BUILD_VERSION=$kubeflowversion
ENV BUILD_COMMIT=$commit

RUN npm install && npm run build && npm prune --production

EXPOSE 8082

ENTRYPOINT ["npm", "start"]
