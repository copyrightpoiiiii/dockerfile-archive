FROM gitpod/workspace-postgres

# Gitpod will not rebuild PeerTube's dev image unless *some* change is made to this Dockerfile.
# To trigger a rebuild, simply increase this counter:
ENV TRIGGER_REBUILD 1

# Install PeerTube's dependencies.
RUN sudo apt-get update -q && sudo apt-get install -qy \
 ffmpeg \
 openssl \
 redis-server

# Set up PostgreSQL.
COPY --chown=gitpod:gitpod support/docker/gitpod/setup_postgres.sql /tmp/
RUN pg_start && psql -h localhost -d postgres --file=/tmp/setup_postgres.sql && pg_stop
