ARG ELASTIC_VERSION

FROM docker.elastic.co/beats/heartbeat:${ELASTIC_VERSION}
