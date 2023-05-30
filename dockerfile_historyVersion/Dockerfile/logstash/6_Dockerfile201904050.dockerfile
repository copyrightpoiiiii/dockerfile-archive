# Logstash 6.7.1

# This image re-bundles the Docker image from the upstream provider, Elastic.
FROM docker.elastic.co/logstash/logstash:6.7.1@sha256:7caa442bfae701cf5b7f101318c5750613bcd8186461282540c3432029860eb5

# The upstream image was built by:
#   https://github.com/elastic/logstash-docker/tree/6.7.1

# For a full list of supported images and tags visit https://www.docker.elastic.co

# For Logstash documentation visit https://www.elastic.co/guide/en/logstash/current/docker.html

# See https://github.com/docker-library/official-images/pull/5039 for more details.
