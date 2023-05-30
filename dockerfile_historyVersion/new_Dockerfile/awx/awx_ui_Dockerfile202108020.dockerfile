FROM node:14
ARG NPMRC_FILE=.npmrc
ENV NPMRC_FILE=${NPMRC_FILE}
ARG TARGET='https://awx:8043'
ENV TARGET=${TARGET}
ENV CI=true
WORKDIR /ui
ADD public public
ADD package.json package.json
ADD package-lock.json package-lock.json
ADD .linguirc .linguirc
COPY ${NPMRC_FILE} .npmrc
RUN npm install
ADD src src
EXPOSE 3001
CMD [ "npm", "start" ]
