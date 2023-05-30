FROM benweet/stackedit-base

RUN mkdir -p /opt/stackedit/stackedit_v4
WORKDIR /opt/stackedit/stackedit_v4

ENV SERVE_V4 true
ENV V4_VERSION 4.3.21
RUN npm pack stackedit@$V4_VERSION \
  && tar xzf stackedit-*.tgz --strip 1 \
  && yarn \
  && yarn cache clean

WORKDIR /opt/stackedit

COPY package.json /opt/stackedit/
COPY yarn.lock /opt/stackedit/
COPY gulpfile.js /opt/stackedit/
RUN npm install
  && npm cache clean --force
  && npm run build
COPY . /opt/stackedit
ENV NODE_ENV production
RUN yarn run build

EXPOSE 8080

CMD [ "node", "." ]
