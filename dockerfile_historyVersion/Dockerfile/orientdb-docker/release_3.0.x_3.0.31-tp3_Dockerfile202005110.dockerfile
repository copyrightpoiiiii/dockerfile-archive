############################################################
# Dockerfile to run an OrientDB (Graph) Container
############################################################

FROM openjdk:8-jdk-slim

MAINTAINER OrientDB LTD (info@orientdb.com)

# Override the orientdb download location with e.g.:
#   docker build -t mine --build-arg ORIENTDB_DOWNLOAD_SERVER=https://repo1.maven.org/maven2/com/orientechnologies/ .
ARG ORIENTDB_DOWNLOAD_SERVER

ENV ORIENTDB_VERSION 3.0.31
ENV ORIENTDB_DOWNLOAD_MD5 9e04918a639a1ab7fd38a1c843f77de9
ENV ORIENTDB_DOWNLOAD_SHA1 b7b50f705e9c813638ba897d784d7c5c83ece4d1

ENV ORIENTDB_DOWNLOAD_URL ${ORIENTDB_DOWNLOAD_SERVER:-https://repo1.maven.org/maven2/com/orientechnologies}/orientdb-tp3/$ORIENTDB_VERSION/orientdb-tp3-$ORIENTDB_VERSION.tar.gz

RUN apt update \
    && apt install -y curl wget \
    && rm -rf /var/lib/apt/lists/* 

#download distribution tar, untar and DON'T delete databases (tp3 endopoint won't works if db isn't present)
RUN mkdir /orientdb && \
  wget  $ORIENTDB_DOWNLOAD_URL \
  && echo "$ORIENTDB_DOWNLOAD_MD5 *orientdb-tp3-$ORIENTDB_VERSION.tar.gz" | md5sum -c - \
  && echo "$ORIENTDB_DOWNLOAD_SHA1 *orientdb-tp3-$ORIENTDB_VERSION.tar.gz" | sha1sum -c - \
  && tar -xvzf orientdb-tp3-$ORIENTDB_VERSION.tar.gz -C /orientdb --strip-components=1 \
  && rm orientdb-tp3-$ORIENTDB_VERSION.tar.gz \
  && rm -rf /orientdb/databases/*


#overrides internal gremlin-server to set binding to 0.0.0.0 instead of localhost
ADD gremlin-server.yaml /orientdb/config

ENV PATH /orientdb/bin:$PATH

VOLUME ["/orientdb/backup", "/orientdb/databases", "/orientdb/config"]

WORKDIR /orientdb

#OrientDb binary
EXPOSE 2424

#OrientDb http
EXPOSE 2480

#Gremlin server
EXPOSE 8182

# Default command start the server
CMD ["server.sh"]
