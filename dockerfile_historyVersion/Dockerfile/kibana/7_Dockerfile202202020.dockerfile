# Kibana 7.17.0

# This image re-bundles the Docker image from the upstream provider, Elastic.
FROM docker.elastic.co/kibana/kibana:7.17.0@sha256:2673a3599185f4ebf363077580064daa817903ccf9fda3ccf6f4fc0abdf0a6eb
# Supported Bashbrew Architectures: amd64 arm64v8

# The upstream image was built by:
#   https://github.com/elastic/dockerfiles/tree/v7.17.0/kibana

# The build can be reproduced locally via:
#   docker build 'https://github.com/elastic/dockerfiles.git#v7.17.0:kibana'

# For a full list of supported images and tags visit https://www.docker.elastic.co

# For documentation visit https://www.elastic.co/guide/en/kibana/current/docker.html

# See https://github.com/docker-library/official-images/pull/4917 for more details.
