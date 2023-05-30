ARG RUST_VERSION
FROM docker.io/rust:${RUST_VERSION}-slim-bullseye

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    g++ \
    libclang1-9 \
    libsasl2-dev \
    libssl-dev \
    llvm-9 \
    pkg-config \
    zlib1g-dev \
  && rm -rf /var/lib/apt/lists/*

RUN rustup run "${RUST_VERSION}" cargo install cargo-nextest --version 0.9.18
