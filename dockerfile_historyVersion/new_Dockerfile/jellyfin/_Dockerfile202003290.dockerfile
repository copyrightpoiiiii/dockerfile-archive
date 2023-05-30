ARG DOTNET_VERSION=3.1
ARG FFMPEG_VERSION=latest

FROM node:alpine as web-builder
ARG JELLYFIN_WEB_VERSION=master
RUN apk add curl git zlib zlib-dev autoconf g++ make libpng-dev gifsicle alpine-sdk automake libtool make gcc musl-dev nasm \
 && curl -L https://github.com/jellyfin/jellyfin-web/archive/${JELLYFIN_WEB_VERSION}.tar.gz | tar zxf - \
 && cd jellyfin-web-* \
 && yarn install \
 && mv dist /dist

FROM mcr.microsoft.com/dotnet/core/sdk:${DOTNET_VERSION}-buster as builder
WORKDIR /repo
COPY . .
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
# because of changes in docker and systemd we need to not build in parallel at the moment
# see https://success.docker.com/article/how-to-reserve-resource-temporarily-unavailable-errors-due-to-tasksmax-setting
RUN dotnet publish Jellyfin.Server --disable-parallel --configuration Release --output="/jellyfin" --self-contained --runtime linux-x64 "-p:GenerateDocumentationFile=false;DebugSymbols=false;DebugType=none"

FROM jellyfin/ffmpeg:${FFMPEG_VERSION} as ffmpeg
FROM debian:buster-slim

# https://askubuntu.com/questions/972516/debian-frontend-environment-variable
ARG DEBIAN_FRONTEND="noninteractive"
# http://stackoverflow.com/questions/48162574/ddg#49462622
ARG APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn
# https://github.com/NVIDIA/nvidia-docker/wiki/Installation-(Native-GPU-Support)
ENV NVIDIA_DRIVER_CAPABILITIES="compute,video,utility"

COPY --from=ffmpeg /opt/ffmpeg /opt/ffmpeg
COPY --from=builder /jellyfin /jellyfin
COPY --from=web-builder /dist /jellyfin/jellyfin-web
# Install dependencies:
#   libfontconfig1: needed for Skia
#   libgomp1: needed for ffmpeg
#   libva-drm2: needed for ffmpeg
#   mesa-va-drivers: needed for VAAPI
RUN apt-get update \
 && apt-get install --no-install-recommends --no-install-suggests -y \
   libfontconfig1 \
   libgomp1 \
   libva-drm2 \
   mesa-va-drivers \
   openssl \
   ca-certificates \
   vainfo \
   i965-va-driver \
   locales \
 && apt-get clean autoclean -y\
 && apt-get autoremove -y\
 && rm -rf /var/lib/apt/lists/* \
 && mkdir -p /cache /config /media \
 && chmod 777 /cache /config /media \
 && ln -s /opt/ffmpeg/bin/ffmpeg /usr/local/bin \
 && ln -s /opt/ffmpeg/bin/ffprobe /usr/local/bin \
 && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen

ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en

EXPOSE 8096
VOLUME /cache /config /media
ENTRYPOINT ["./jellyfin/jellyfin", \
    "--datadir", "/config", \
    "--cachedir", "/cache", \
    "--ffmpeg", "/usr/local/bin/ffmpeg"]
