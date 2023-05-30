FROM python:3.6.8-stretch

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

LABEL com.nvidia.volumes.needed="nvidia_driver"

WORKDIR /stage/allennlp

# Install base packages.
RUN apt-get update --fix-missing && apt-get install -y \
    bzip2 \
    ca-certificates \
    curl \
    gcc \
    git \
    libc-dev \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    wget \
    libevent-dev \
    build-essential && \
    rm -rf /var/lib/apt/lists/*

# Copy select files needed for installing requirements.
# We only copy what we need here so small changes to the repository does not trigger re-installation of the requirements.
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY scripts/ scripts/
COPY allennlp/ allennlp/
COPY pytest.ini pytest.ini
COPY .pylintrc .pylintrc
COPY tutorials/ tutorials/
COPY training_config training_config/
COPY setup.py setup.py
COPY README.md README.md

RUN pip install --editable .

# Compile EVALB - required for parsing evaluation.
# EVALB produces scary looking c-level output which we don't
# care about, so we redirect the output to /dev/null.
RUN cd allennlp/tools/EVALB && make &> /dev/null && cd ../../../

# Caching models when building the image makes a dockerized server start up faster, but is slow for
# running tests and things, so we skip it by default.
ARG CACHE_MODELS=false
RUN ./scripts/cache_models.py


# Optional argument to set an environment variable with the Git SHA
ARG SOURCE_COMMIT
ENV ALLENNLP_SOURCE_COMMIT $SOURCE_COMMIT

# Copy wrapper script to allow beaker to run resumable training workloads.
COPY scripts/ai2-internal/resumable_train.sh /stage/allennlp

LABEL maintainer="allennlp-contact@allenai.org"

EXPOSE 8000
CMD ["/bin/bash"]
