# Logstash 7.14.1

# This image re-bundles the Docker image from the upstream provider, Elastic.
FROM docker.elastic.co/logstash/logstash:7.14.1@sha256:eb2d60ba01e4aabb28001bf1b17ba69f6c5039746103e004d519f433ab5d584c
# Supported Bashbrew Architectures: amd64 arm64v8

# The upstream image was built by:
#   https://github.com/elastic/dockerfiles/tree/v7.14.1/logstash

# The build can be reproduced locally via:
#   docker build 'https://github.com/elastic/dockerfiles.git#v7.14.1:logstash'

# For a full list of supported images and tags visit https://www.docker.elastic.co

# For Logstash documentation visit https://www.elastic.co/guide/en/logstash/current/docker.html

# See https://github.com/docker-library/official-images/pull/5039 for more details.
