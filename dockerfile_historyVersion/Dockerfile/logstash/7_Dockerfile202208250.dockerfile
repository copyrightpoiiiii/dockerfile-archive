# Logstash 7.17.6

# This image re-bundles the Docker image from the upstream provider, Elastic.
FROM docker.elastic.co/logstash/logstash:7.17.6@sha256:8621b44dcc2e93c27a3d5c8c787387eb8db6072245fc5c8c44adf960ca8eca16
# Supported Bashbrew Architectures: amd64 arm64v8

# The upstream image was built by:
#   https://github.com/elastic/dockerfiles/tree/v7.17.6/logstash

# The build can be reproduced locally via:
#   docker build 'https://github.com/elastic/dockerfiles.git#v7.17.6:logstash'

# For a full list of supported images and tags visit https://www.docker.elastic.co

# For Logstash documentation visit https://www.elastic.co/guide/en/logstash/current/docker.html

# See https://github.com/docker-library/official-images/pull/5039 for more details.
