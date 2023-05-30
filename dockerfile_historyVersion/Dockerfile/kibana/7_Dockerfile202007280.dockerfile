# Kibana 7.8.1

# This image re-bundles the Docker image from the upstream provider, Elastic.
FROM docker.elastic.co/kibana/kibana:7.8.1@sha256:2a9cc31f8836d857f816c693c92c3bcacf0bd3060ac4d3183374e68e38540c2c

# The upstream image was built by:
#   https://github.com/elastic/dockerfiles/tree/v7.8.1/kibana

# The build can be reproduced locally via:
#   docker build 'https://github.com/elastic/dockerfiles.git#v7.8.1:kibana'

# For a full list of supported images and tags visit https://www.docker.elastic.co

# For documentation visit https://www.elastic.co/guide/en/kibana/current/docker.html

# See https://github.com/docker-library/official-images/pull/4917 for more details.
