ARG IMAGE=openliberty/open-liberty:kernel-ubi
FROM ${IMAGE}

COPY --chown=1001:0 config /config/
COPY --chown=1001:0 stock-quote-1.0-SNAPSHOT.war /config/apps/StockQuote.war

ARG VERBOSE=false

RUN configure.sh
