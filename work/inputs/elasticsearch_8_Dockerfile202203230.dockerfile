# Elasticsearch 8.1.1

# This image re-bundles the Docker image from the upstream provider, Elastic.
FROM docker.elastic.co/elasticsearch/elasticsearch:8.1.1@sha256:2b75a3e2d4a296682dd598415b8921c931059562bbbf29c1e5c0d9c342d2a301
# Supported Bashbrew Architectures: amd64 arm64v8

# The upstream image was built by:
#   https://github.com/elastic/dockerfiles/tree/v8.1.1/elasticsearch

# The build can be reproduced locally via:
#   docker build 'https://github.com/elastic/dockerfiles.git#v8.1.1:elasticsearch'

# For a full list of supported images and tags visit https://www.docker.elastic.co

# For Elasticsearch documentation visit https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html

# See https://github.com/docker-library/official-images/pull/4916 for more details.
