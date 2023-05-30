# Using multistage build: 
#  https://docs.docker.com/develop/develop-images/multistage-build/
#  https://whitfin.io/speeding-up-rust-docker-builds/
####################### VAULT BUILD IMAGE  #######################
FROM node:8-alpine as vault

ENV VAULT_VERSION "v2.5.0"

ENV URL "https://github.com/bitwarden/web.git"

RUN apk add --update-cache --upgrade \
    curl \
    git \
    tar

RUN git clone -b $VAULT_VERSION --depth 1 $URL web-build
WORKDIR /web-build

COPY /docker/set-vault-baseurl.patch /web-build/    
RUN git apply set-vault-baseurl.patch

RUN npm run sub:init && npm install

RUN npm run dist \
    && mv build /web-vault

########################## BUILD IMAGE  ##########################
# We need to use the Rust build image, because
# we need the Rust compiler and Cargo tooling
FROM rust as build

# Using bundled SQLite, no need to install it
# RUN apt-get update && apt-get install -y\
#    sqlite3\
#    --no-install-recommends\
# && rm -rf /var/lib/apt/lists/*

# Creates a dummy project used to grab dependencies
RUN USER=root cargo new --bin app
WORKDIR /app

# Copies over *only* your manifests and vendored dependencies
COPY ./Cargo.* ./
COPY ./libs ./libs
COPY ./rust-toolchain ./rust-toolchain

# Builds your dependencies and removes the
# dummy project, except the target folder
# This folder contains the compiled dependencies
RUN cargo build --release
RUN find . -not -path "./target*" -delete

# Copies the complete project
# To avoid copying unneeded files, use .dockerignore
COPY . .

# Builds again, this time it'll just be
# your actual source files being built
RUN cargo build --release

######################## RUNTIME IMAGE  ########################
# Create a new stage with a minimal image
# because we already have a binary built
FROM debian:stretch-slim

ENV ROCKET_ENV "staging"
ENV ROCKET_WORKERS=10

# Install needed libraries
RUN apt-get update && apt-get install -y\
    openssl\
    ca-certificates\
    --no-install-recommends\
 && rm -rf /var/lib/apt/lists/*

RUN mkdir /data
VOLUME /data
EXPOSE 80
EXPOSE 3012

# Copies the files from the context (env file and web-vault)
# and the binary from the "build" stage to the current stage
COPY .env .
COPY Rocket.toml .
COPY --from=vault /web-vault ./web-vault
COPY --from=build app/target/release/bitwarden_rs .

# Configures the startup!
CMD ./bitwarden_rs
