FROM mcr.microsoft.com/vscode/devcontainers/rust:0-1

# Update to Rust 1.58.0
RUN rustup update 1.58.0 && rustup default 1.58.0

# Install Deno
ENV DENO_INSTALL=/usr/local
RUN curl -fsSL https://deno.land/x/install/install.sh | sh
