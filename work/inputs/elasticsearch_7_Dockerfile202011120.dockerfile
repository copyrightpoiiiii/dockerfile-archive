# Elasticsearch 7.10.0

# This image re-bundles the Docker image from the upstream provider, Elastic.
FROM docker.elastic.co/elasticsearch/elasticsearch:7.10.0@sha256:3ad224719013a016ab4931d1891fcf873fdf6b8c38d0970e30fc1c8b0c07f436
# Supported Bashbrew Architectures: amd64 arm64v8

# The upstream image was built by:
#   https://github.com/elastic/dockerfiles/tree/v7.10.0/elasticsearch

# The build can be reproduced locally via:
#   docker build 'https://github.com/elastic/dockerfiles.git#v7.10.0:elasticsearch'

# For a full list of supported images and tags visit https://www.docker.elastic.co

# For Elasticsearch documentation visit https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html

# See https://github.com/docker-library/official-images/pull/4916 for more details.
