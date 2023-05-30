# Logstash 8.4.1

# This image re-bundles the Docker image from the upstream provider, Elastic.
FROM docker.elastic.co/logstash/logstash:8.4.1@sha256:924d115e4d7c7970003691b856e1fe3b87e2748a0973bb0c295c1c5c72ebdf8b
# Supported Bashbrew Architectures: amd64 arm64v8

# The upstream image was built by:
#   https://github.com/elastic/dockerfiles/tree/v8.4.1/logstash

# The build can be reproduced locally via:
#   docker build 'https://github.com/elastic/dockerfiles.git#v8.4.1:logstash'

# For a full list of supported images and tags visit https://www.docker.elastic.co

# For Logstash documentation visit https://www.elastic.co/guide/en/logstash/current/docker.html

# See https://github.com/docker-library/official-images/pull/5039 for more details.