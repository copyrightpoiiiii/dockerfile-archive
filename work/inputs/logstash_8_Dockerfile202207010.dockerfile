# Logstash 8.3.1

# This image re-bundles the Docker image from the upstream provider, Elastic.
FROM docker.elastic.co/logstash/logstash:8.3.1@sha256:208aa4878c510ea10923c39fc0851a831f10df15913f88bdacbc6fff80d08a96
# Supported Bashbrew Architectures: amd64 arm64v8

# The upstream image was built by:
#   https://github.com/elastic/dockerfiles/tree/v8.3.1/logstash

# The build can be reproduced locally via:
#   docker build 'https://github.com/elastic/dockerfiles.git#v8.3.1:logstash'

# For a full list of supported images and tags visit https://www.docker.elastic.co

# For Logstash documentation visit https://www.elastic.co/guide/en/logstash/current/docker.html

# See https://github.com/docker-library/official-images/pull/5039 for more details.
