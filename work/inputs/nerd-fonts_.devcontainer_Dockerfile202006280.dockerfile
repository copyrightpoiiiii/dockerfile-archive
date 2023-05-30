ARG VARIANT="3"
FROM mcr.microsoft.com/vscode/devcontainers/python:0-${VARIANT}

RUN apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install --no-install-recommends -y bc fontforge python-configparser \
    && fontforge --version 2>&1
