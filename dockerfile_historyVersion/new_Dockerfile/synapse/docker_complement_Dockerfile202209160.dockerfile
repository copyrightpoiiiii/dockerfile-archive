# syntax=docker/dockerfile:1
# This dockerfile builds on top of 'docker/Dockerfile-workers' in matrix-org/synapse
# by including a built-in postgres instance, as well as setting up the homeserver so
# that it is ready for testing via Complement.
#
# Instructions for building this image from those it depends on is detailed in this guide:
# https://github.com/matrix-org/synapse/blob/develop/docker/README-testing.md#testing-with-postgresql-and-single-or-multi-process-synapse

ARG SYNAPSE_VERSION=latest

# first of all, we create a base image with a postgres server and database,
# which we can copy into the target image. For repeated rebuilds, this is
# much faster than apt installing postgres each time.
#
# This trick only works because (a) the Synapse image happens to have all the
# shared libraries that postgres wants, (b) we use a postgres image based on
# the same debian version as Synapse's docker image (so the versions of the
# shared libraries match).

# now build the final image, based on the Synapse image.

FROM matrixdotorg/synapse-workers:$SYNAPSE_VERSION
    # copy the postgres installation over from the image we built above
    RUN adduser --system --uid 999 postgres --home /var/lib/postgresql
    COPY --from=postgres:13-bullseye /usr/lib/postgresql /usr/lib/postgresql
    COPY --from=postgres:13-bullseye /usr/share/postgresql /usr/share/postgresql
    RUN mkdir /var/run/postgresql && chown postgres /var/run/postgresql
    ENV PATH="${PATH}:/usr/lib/postgresql/13/bin"
    ENV PGDATA=/var/lib/postgresql/data

    # initialise the database cluster in /var/lib/postgresql
    RUN gosu postgres initdb --locale=C --encoding=UTF-8 --auth-host password

    # Configure a password and create a database for Synapse
    RUN echo "ALTER USER postgres PASSWORD 'somesecret'" | gosu postgres postgres --single
    RUN echo "CREATE DATABASE synapse" | gosu postgres postgres --single

    # Extend the shared homeserver config to disable rate-limiting,
    # set Complement's static shared secret, enable registration, amongst other
    # tweaks to get Synapse ready for testing.
    # To do this, we copy the old template out of the way and then include it
    # with Jinja2.
    RUN mv /conf/shared.yaml.j2 /conf/shared-orig.yaml.j2
    COPY conf/workers-shared-extra.yaml.j2 /conf/shared.yaml.j2

    WORKDIR /data

    COPY conf/postgres.supervisord.conf /etc/supervisor/conf.d/postgres.conf

    # Copy the entrypoint
    COPY conf/start_for_complement.sh /

    # Expose nginx's listener ports
    EXPOSE 8008 8448

    ENTRYPOINT ["/start_for_complement.sh"]

    # Update the healthcheck to have a shorter check interval
    HEALTHCHECK --start-period=5s --interval=1s --timeout=1s \
        CMD /bin/sh /healthcheck.sh
