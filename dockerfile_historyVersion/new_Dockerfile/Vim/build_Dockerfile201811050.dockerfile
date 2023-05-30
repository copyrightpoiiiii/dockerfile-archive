FROM node:8.12

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y xorg xvfb libxss-dev libgtk-3-0 gconf2 libnss3 libasound2

ENV CXX="g++-4.9"
ENV CC="gcc-4.9"
ENV DISPLAY=:99.0

WORKDIR /app

ENTRYPOINT ["sh", "-c", "(Xvfb $DISPLAY -screen 0 1024x768x16 &) && npm run test"]
