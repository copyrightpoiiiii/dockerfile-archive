#### Base Image: Debian 11, Codename "Bullseye"
FROM debian:bullseye-slim

LABEL maintainer="Michael Mayer <hello@photoprism.app>"

ARG TARGETARCH
ARG BUILD_TAG

# set environment variables
ENV DOCKER_ARCH=$TARGETARCH \
    DOCKER_TAG=$BUILD_TAG \
    DOCKER_ENV="develop" \
    NODE_ENV="production" \
    DEBIAN_FRONTEND="noninteractive" \
    TMPDIR="/tmp" \
    LD_LIBRARY_PATH="/root/.local/lib:/usr/local/lib:/usr/lib:/lib" \
    TF_CPP_MIN_LOG_LEVEL="0" \
    GOPATH="/go" \
    GOBIN="/go/bin" \
    PATH="/go/bin:/usr/local/go/bin:~/.local/bin:/root/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    GO111MODULE="on" \
    CGO_CFLAGS="-g -O2 -Wno-return-local-addr"

# copy scripts and debian backports sources list
COPY --chown=root:root --chmod=755 /scripts/dist/* /root/.local/bin/
COPY --chown=root:root --chmod=644 /docker/develop/bullseye/backports.list /etc/apt/sources.list.d/backports.list
COPY --chown=root:root --chmod=755 /docker/develop/entrypoint.sh /entrypoint.sh
COPY --chown=root:root --chmod=644 /.my.cnf /etc/my.cnf

# update image and install build dependencies
RUN echo 'Acquire::Retries "10";' > /etc/apt/apt.conf.d/80retry && \
    echo 'APT::Install-Recommends "false";' > /etc/apt/apt.conf.d/80recommends && \
    echo 'APT::Install-Suggests "false";' > /etc/apt/apt.conf.d/80suggests && \
    echo 'APT::Get::Assume-Yes "true";' > /etc/apt/apt.conf.d/80forceyes && \
    echo 'APT::Get::Fix-Missing "true";' > /etc/apt/apt.conf.d/80fixmissing && \
    useradd -m -U -u 1000 -d /photoprism photoprism && \
    apt-get update && apt-get -qq dist-upgrade && apt-get -qq install --no-install-recommends \
      apt-utils \
      gpg \
      pkg-config \
      software-properties-common \
      ca-certificates \
      build-essential \
      gcc \
      g++ \
      sudo \
      make \
      nano \
      git \
      zip \
      wget \
      curl \
      rsync \
      unzip \
      sqlite3 \
      chrpath \
      gettext \
      libc6-dev \
      libssl-dev \
      libxft-dev \
      libfreetype6 \
      libfreetype6-dev \
      libfontconfig1 \
      libfontconfig1-dev \
      libhdf5-serial-dev \
      libpng-dev \
      libzmq3-dev \
      libx264-dev \
      libx265-dev \
      libnss3 \
      libxtst6 \
      librsvg2-bin \
      tzdata \
      libheif-examples \
      exiftool \
      ffmpeg \
      ffmpegthumbnailer \
      libavcodec-extra \
      sudo && \
    /root/.local/bin/install-nodejs.sh && \
    /root/.local/bin/install-tensorflow.sh && \
    /root/.local/bin/install-go.sh && \
    /root/.local/bin/cleanup.sh && \
    mkdir -p "/go/src" "/go/bin" && \
    chmod -R 777 "/go" && \
    install -d -m 0777 -o 1000 -g 1000 \
      /var/lib/photoprism \
      /tmp/photoprism \
      /photoprism/originals \
      /photoprism/import \
      /photoprism/storage \
      /photoprism/storage/sidecar \
      /photoprism/storage/albums \
      /photoprism/storage/backups \
      /photoprism/storage/config \
      /photoprism/storage/cache && \
    wget "https://dl.photoprism.app/tensorflow/nsfw.zip?${BUILD_TAG}" -O /tmp/photoprism/nsfw.zip && \
    wget "https://dl.photoprism.app/tensorflow/nasnet.zip?${BUILD_TAG}" -O /tmp/photoprism/nasnet.zip && \
    wget "https://dl.photoprism.app/tensorflow/facenet.zip?${BUILD_TAG}" -O /tmp/photoprism/facenet.zip && \
    wget "https://dl.photoprism.app/qa/testdata.zip?${BUILD_TAG}" -O /tmp/photoprism/testdata.zip

# install Go tools
RUN /usr/local/go/bin/go install github.com/tianon/gosu@latest; \
    cp /go/bin/gosu /bin/gosu && \
    echo "alias ll='ls -alh'" > /photoprism/.bash_aliases && \
    echo "alias ll='ls -alh'" > /root/.bash_aliases && \
    echo "ALL ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/all && \
    cp /root/.local/bin/heif-convert.sh /usr/local/bin/heif-convert && \
    chmod -R a+rwX /go

# set up project directory
WORKDIR "/go/src/github.com/photoprism/photoprism"

# expose the following container ports:
# - 2342 (HTTP)
# - 2343 (Acceptance Tests)
# - 9515 (Chromedriver)
# - 40000 (Go Debugger)
EXPOSE 2342 2343 9515 40000

# define container entrypoint script
ENTRYPOINT ["/entrypoint.sh"]

# keep container running
CMD ["tail", "-f", "/dev/null"]
