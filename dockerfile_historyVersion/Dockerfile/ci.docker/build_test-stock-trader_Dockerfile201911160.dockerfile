ARG IMAGE=openliberty/open-liberty:kernel-ubi
FROM ${IMAGE}

COPY --chown=1001:0 config /config/
COPY --chown=1001:0 trader-1.0-SNAPSHOT.war /config/apps/TraderUI.war

RUN configure.sh
