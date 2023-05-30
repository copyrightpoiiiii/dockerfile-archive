# Elasticsearch 6.8.18

# This image re-bundles the Docker image from the upstream provider, Elastic.
FROM docker.elastic.co/elasticsearch/elasticsearch:6.8.18@sha256:41a54986324f4e1998be54489830c78052515d2d76d5ec937b0de69c1433d480
# Supported Bashbrew Architectures: amd64

# The upstream image was built by:
#   https://github.com/elastic/dockerfiles/tree/v6.8.18/elasticsearch

# The build can be reproduced locally via:
#   docker build 'https://github.com/elastic/dockerfiles.git#v6.8.18:elasticsearch'

# For a full list of supported images and tags visit https://www.docker.elastic.co

# For Elasticsearch documentation visit https://www.elastic.co/guide/en/elasticsearch/reference/current/docker.html

# See https://github.com/docker-library/official-images/pull/4916 for more details.