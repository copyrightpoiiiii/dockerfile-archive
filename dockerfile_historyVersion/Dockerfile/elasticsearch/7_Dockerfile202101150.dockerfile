# Elasticsearch 7.10.2

# This image re-bundles the Docker image from the upstream provider, Elastic.
FROM docker.elastic.co/elasticsearch/elasticsearch:7.10.2@sha256:d528cec81720266974fdfe7a0f12fee928dc02e5a2c754b45b9a84c84695bfd9
# Supported Bashbrew Architectures: amd64 arm64v8

# The upstream image was built by:
#   https://github.com/elastic/dockerfiles/tree/v7.10.2/elasticsearch

# The build can be reproduced locally via:
#   docker build 'https://github.com/elastic/dockerfiles.git#v7.10.2:elasticsearch'

# For a full list of supported images and tags visit https://www.docker.elastic.co

# For Elasticsearch documentation visit https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html

# See https://github.com/docker-library/official-images/pull/4916 for more details.
