# docker build -t yandex/clickhouse-performance-comparison .
FROM ubuntu:18.04

ENV LANG=C.UTF-8
ENV TZ=Europe/Moscow
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
            bash \
            curl \
            g++ \
            gdb \
            git \
            gnuplot \
            imagemagick \
            libc6-dbg \
            moreutils \
            ncdu \
            numactl \
            p7zip-full \
            parallel \
            psmisc \
            python3 \
            python3-dev \
            python3-pip \
            rsync \
            tree \
            tzdata \
            vim \
            wget \
    && pip3 --no-cache-dir install clickhouse_driver scipy \
    && apt-get purge --yes python3-dev g++ \
    && apt-get autoremove --yes \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY * /

# Bind everything to NUMA node #1, if there's more than one. We avoid node #0,
# because it is more susceptible to system interruptions. We have to bind both
# servers and the tmpfs on which the database is stored. How to do it through
# Yandex Sandbox API is unclear, but by default tmpfs uses 'process allocation
# policy', not sure which process but hopefully the one that writes to it, so
# just bind the downloader script as well.
# We could also try to remount it with proper options in Sandbox task.
# https://www.kernel.org/doc/Documentation/filesystems/tmpfs.txt
CMD ["bash", "-c", "node=$(numactl --hardware | grep -q 'available: 1 nodes' && echo 0 || echo 1); echo Will bind to NUMA node $node; numactl --cpunodebind=$node --membind=$node /entrypoint.sh"]

# docker run --network=host --volume <workspace>:/workspace --volume=<output>:/output -e PR_TO_TEST=<> -e SHA_TO_TEST=<> yandex/clickhouse-performance-comparison