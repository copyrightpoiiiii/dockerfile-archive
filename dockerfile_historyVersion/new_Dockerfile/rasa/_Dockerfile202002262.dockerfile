FROM python:3.6-slim as python_builder
RUN apt-get update -qq && \
  apt-get install -y --no-install-recommends \
  build-essential \
  wget \
  openssh-client \
  graphviz-dev \
  pkg-config \
  git-core \
  openssl \
  libssl-dev \
  libffi6 \
  libffi-dev \
  libpng-dev \
  # required by psycopg2 at build and runtime
  libpq-dev \
  curl

# install poetry
# keep this in sync with the version in pyproject.toml and Dockerfile
ENV POETRY_VERSION 1.0.3
RUN curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python
ENV PATH "/root/.poetry/bin:/opt/venv/bin:${PATH}"

# copy files
COPY . /app/

# install dependencies
RUN python -m venv /opt/venv && \
  . /opt/venv/bin/activate && \
  pip install --no-cache-dir -U 'pip<20' && \
  cd /app && \
  poetry install --no-dev --no-interaction

# start a new build stage
FROM python_builder as runner

# copy everything from /opt
COPY --from=python_builder /opt/venv /opt/venv

# make sure we use the virtualenv
ENV PATH="/opt/venv/bin:$PATH"

# update permissions & change user to not run as root
RUN chgrp -R 0 /app && chmod -R g=u /app
USER 1001

# create a volume for temporary data
VOLUME /tmp

# change shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# the entry point
WORKDIR /app
EXPOSE 5005
ENTRYPOINT ["rasa"]
CMD ["--help"]
