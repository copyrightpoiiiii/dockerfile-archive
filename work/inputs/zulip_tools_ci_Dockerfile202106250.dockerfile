# Dockerfile for a generic Ubuntu image with just the basics we need
# to make it suitable for CI.  In particular:
#  * a non-root user to run as (a pain to try to do in setup,
#    because by then we've already cloned the repo);
#  * Git and other basic utilities.
#
# Based on CircleCI's provided images, but those are on Debian Jessie
# and we want Ubuntu, to match our supported environments in production.
# See these templates and code:
#   https://github.com/circleci/circleci-images/blob/1949c44df/shared/images/
# which we've borrowed from, chiefly Dockerfile-basic.template.
#
# The CircleCI `python` images are based on upstream's `python` (i.e.,
# https://hub.docker.com/_/python/), which also come only for Debian
# (and various obscure distros, and Windows) and not Ubuntu.  Those
# are in turn based on upstream's `buildpack-deps`, which do come in
# Ubuntu flavors.
#
# So this image starts from `buildpack-deps`, does the job of `python`
# (but much simpler, with a couple of packages from the distro), and
# then borrows from the CircleCI Dockerfile.

# To rebuild from this file for a given release, say bionic:
#   docker build . --build-arg=BASE_IMAGE=buildpack-deps:bionic-scm --pull --tag=zulip/ci:bionic
#   docker push zulip/ci:bionic

ARG BASE_IMAGE
FROM $BASE_IMAGE

RUN echo 'APT::Get::Assume-Yes "true";' > /etc/apt/apt.conf.d/90circleci \
  && echo 'DPkg::Options "--force-confnew";' >> /etc/apt/apt.conf.d/90circleci
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install -y \
    sudo \
    locales \
    xvfb \
    parallel \
    unzip zip jq \
    python3-pip \
  && ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime \
  && echo "LC_ALL=C.UTF-8" | sudo tee -a /etc/default/locale

# Set the locale, together with the locale-related steps above.
ENV LC_ALL C.UTF-8

# Install Docker.  This logic comes from Circle's Dockerfile; it's probably
# faster than the upstream-recommended approach of using their apt repo,
# and fine for an image that will be rebuilt rather than upgraded.

# Docker core...
RUN set -e \
  && export DOCKER_VERSION=$(curl --silent --fail --retry 3 https://download.docker.com/linux/static/stable/x86_64/ | grep -o -e 'docker-[.0-9]*-ce\.tgz' | sort -r | head -n 1) \
  && DOCKER_URL="https://download.docker.com/linux/static/stable/x86_64/${DOCKER_VERSION}" \
  && echo Docker URL: $DOCKER_URL \
  && curl --silent --show-error --location --fail --retry 3 --output /tmp/docker.tgz "${DOCKER_URL}" \
  && ls -lha /tmp/docker.tgz \
  && tar -xz -C /tmp -f /tmp/docker.tgz \
  && mv /tmp/docker/* /usr/bin \
  && rm -rf /tmp/docker /tmp/docker.tgz \
  && command -v docker \
  && (docker version 2>/dev/null || true)

# ...docker-compose...
RUN COMPOSE_URL="https://circle-downloads.s3.amazonaws.com/circleci-images/cache/linux-amd64/docker-compose-latest" \
  && curl --silent --show-error --location --fail --retry 3 --output /usr/bin/docker-compose $COMPOSE_URL \
  && chmod +x /usr/bin/docker-compose \
  && docker-compose version

# ... and dockerize.
RUN DOCKERIZE_URL="https://circle-downloads.s3.amazonaws.com/circleci-images/cache/linux-amd64/dockerize-latest.tar.gz" \
  && curl --silent --show-error --location --fail --retry 3 --output /tmp/dockerize-linux-amd64.tar.gz $DOCKERIZE_URL \
  && tar -C /usr/local/bin -xzvf /tmp/dockerize-linux-amd64.tar.gz \
  && rm -rf /tmp/dockerize-linux-amd64.tar.gz \
  && dockerize --version

# Extra packages used by Zulip.
RUN apt-get update \
  && apt-get install --no-install-recommends \
    memcached rabbitmq-server redis-server \
    hunspell-en-us supervisor libssl-dev puppet \
    gettext libffi-dev libfreetype6-dev zlib1g-dev \
    libjpeg-dev libldap2-dev \
    libxml2-dev libxslt1-dev libpq-dev moreutils

# Upgrade git if it is less than v2.18 because GitHub Actions'
# checkout installs source code using Rest API as an optimization
# if the version is less than v2.18, which causes failure in provision
# and tests because of the lack of git being initialized.
RUN export git_version=$(git --version | cut -d ' ' -f3 | cut -d 'v' -f2) && \
    if dpkg --compare-versions $git_version lt 2.18; then \
      sudo apt-get install -y software-properties-common && \
      sudo add-apt-repository ppa:git-core/ppa -y && \
      sudo apt-get update && \
      sudo apt-get install -y git; \
    fi

# Remove systemd package as it is not required and hinders with install
RUN if [ ! "$(dpkg-query -f='$(Version)' --show systemd)" = "" ]; then \
      apt-get remove --purge --auto-remove systemd -y && \
      echo 'Package: systemd\nPin: release *\nPin-Priority: -1' | sudo tee -a /etc/apt/preferences.d/systemd && \
      echo '\n\nPackage: *systemd*\nPin: release *\nPin-Priority: -1' | sudo tee -a /etc/apt/preferences.d/systemd && \
      echo '\nPackage: systemd:amd64\nPin: release *\nPin-Priority: -1' | sudo tee -a /etc/apt/preferences.d/systemd; \
    fi

ARG USERNAME=github
RUN groupadd --gid 3434 $USERNAME \
  && useradd --uid 3434 --gid $USERNAME --shell /bin/bash --create-home $USERNAME \
  && echo "$USERNAME ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers.d/50-$USERNAME \
  && echo 'Defaults    env_keep += "DEBIAN_FRONTEND"' >> /etc/sudoers.d/env_keep

USER $USERNAME

CMD ["/bin/sh"]
