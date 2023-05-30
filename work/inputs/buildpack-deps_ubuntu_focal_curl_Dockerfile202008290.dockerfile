#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM ubuntu:focal

RUN apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  netbase \
  wget \
 && rm -rf /var/lib/apt/lists/*

RUN set -ex; \
 if ! command -v gpg > /dev/null; then \
  apt-get update; \
  apt-get install -y --no-install-recommends \
   gnupg \
   dirmngr \
  ; \
  rm -rf /var/lib/apt/lists/*; \
 fi
