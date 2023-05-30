# -- DEV DOCKERFILE --
# -- DO NOT USE IN PRODUCTION! --

FROM node:12-alpine
LABEL maintainer "requarks.io"

RUN apk update && \
    apk add bash curl git python make g++ nano openssh gnupg --no-cache && \
    mkdir -p /wiki

WORKDIR /wiki

ENV dockerdev 1
ENV DEVDB postgres

EXPOSE 3000

CMD ["tail", "-f", "/dev/null"]