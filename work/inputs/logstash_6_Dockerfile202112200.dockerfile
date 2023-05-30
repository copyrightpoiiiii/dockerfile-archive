# Logstash 6.8.22

# This image re-bundles the Docker image from the upstream provider, Elastic.
FROM docker.elastic.co/logstash/logstash:6.8.22@sha256:1995148cdefd7031407fa668a7e7a27f603b0cc810bd6e24a1638afee4079bf2
# Supported Bashbrew Architectures: amd64

# The upstream image was built by:
#   https://github.com/elastic/dockerfiles/tree/v6.8.22/logstash

# The build can be reproduced locally via:
#   docker build 'https://github.com/elastic/dockerfiles.git#v6.8.22:logstash'

# For a full list of supported images and tags visit https://www.docker.elastic.co

# For Logstash documentation visit https://www.elastic.co/guide/en/logstash/current/docker.html

# See https://github.com/docker-library/official-images/pull/5039 for more details.