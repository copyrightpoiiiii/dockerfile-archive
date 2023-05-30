ARG BUILD_FROM=postgres:11
FROM ${BUILD_FROM}
ARG POSTGRES_USER=postgres
COPY --chown=$POSTGRES_USER .ci/docker-compose-file/pgsql/pg_hba.conf /var/lib/postgresql/pg_hba.conf
COPY --chown=$POSTGRES_USER apps/emqx/etc/certs/key.pem /var/lib/postgresql/server.key
COPY --chown=$POSTGRES_USER apps/emqx/etc/certs/cert.pem /var/lib/postgresql/server.crt
COPY --chown=$POSTGRES_USER apps/emqx/etc/certs/cacert.pem /var/lib/postgresql/root.crt
RUN chmod 600 /var/lib/postgresql/pg_hba.conf
RUN chmod 600 /var/lib/postgresql/server.key
RUN chmod 600 /var/lib/postgresql/server.crt
RUN chmod 600 /var/lib/postgresql/root.crt
EXPOSE 5432
