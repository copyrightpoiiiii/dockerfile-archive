FROM ubuntu:20.04

ENV \
    #
    # Some APT packages like 'tzdata' wait for user input on install by default.
    # https://stackoverflow.com/questions/44331836/apt-get-install-tzdata-noninteractive
    DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LANGUAGE=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN \
    apt-get update -q && \
    apt-get install -qy --no-install-recommends \
        #
        # Cloning the repository
        git \
        ca-certificates \
        #
        # Running mach with Python 3
        python3 \
        python3-pip \
        python3-dev \
        virtualenv \
        #
        # Compiling C modules when installing Python packages in a virtualenv
        gcc \
        #
        # Installing rustup and sccache (build dockerfile) or fetching build artifacts (run tasks)
        curl \
        # Setting the default locale
        locales \
        locales-all

RUN \
    apt-get install -qy --no-install-recommends \
        #
        # Testing decisionlib (see etc/taskcluster/mock.py)
        python3-coverage \
        #
        # Multiple C/C++ dependencies built from source
        g++ \
        make \
        cmake \
        #
        # Fontconfig
        gperf \
        #
        # ANGLE
        xorg-dev \
        #
        # mozjs (SpiderMonkey)
        autoconf2.13 \
        #
        # Bindgen (for SpiderMonkey bindings)
        clang \
        llvm \
        llvm-dev \
        #
        # GStreamer
        libpcre3-dev \
        #
        # OpenSSL
        libssl-dev \
        #
        # blurz
        libdbus-1-dev \
        #
        # sampling profiler
        libunwind-dev \
        #
        # x11 integration
        libxcb-render-util0-dev \
        libxcb-shape0-dev \
        libxcb-xfixes0-dev \
        #
    && \
    #
    # Install the version of rustup that is current when this Docker image is being built:
    # We want at least 1.21 (increment in this comment to force an image rebuild).
    curl https://sh.rustup.rs -sSf | sh -s -- --profile=minimal -y && \
    #
    # There are no sccache binary releases that include this commit, so we install a particular
    # git commit instead.
    ~/.cargo/bin/cargo install sccache --git https://github.com/mozilla/sccache/ --rev e66c9c15142a7e583d6ab80bd614bdffb2ebcc47
