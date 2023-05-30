FROM debian:bullseye

ENV JAVA_HOME=/opt/java/openjdk
COPY --from=eclipse-temurin:19 $JAVA_HOME $JAVA_HOME
ENV PATH="${JAVA_HOME}/bin:${PATH}"

ENV LEIN_VERSION=2.9.10
ENV LEIN_INSTALL=/usr/local/bin/

WORKDIR /tmp

# Download the whole repo as an archive
RUN set -eux; \
apt-get update && \
apt-get install -y make gnupg wget && \
rm -rf /var/lib/apt/lists/* && \
mkdir -p $LEIN_INSTALL && \
wget -q https://codeberg.org/leiningen/leiningen/raw/tag/$LEIN_VERSION/bin/lein-pkg && \
echo "Comparing lein-pkg checksum ..." && \
sha256sum lein-pkg && \
echo "dbb84d13d6df5b85bbf7f89a39daeed103133c24a4686d037fe6bd65e38e7f32 *lein-pkg" | sha256sum -c - && \
mv lein-pkg $LEIN_INSTALL/lein && \
chmod 0755 $LEIN_INSTALL/lein && \
export GNUPGHOME="$(mktemp -d)" && \
export FILENAME_EXT=jar && \
if printf '%s\n%s\n' "2.9.7" "$LEIN_VERSION" | sort -cV; then \
              gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys 6A2D483DB59437EBB97D09B1040193357D0606ED; \
            else \
              gpg --batch --keyserver hkps://keyserver.ubuntu.com --recv-keys 20242BACBBE95ADA22D0AFD7808A33D379C806C3; \
              FILENAME_EXT=zip; \
            fi && \
wget -q https://codeberg.org/leiningen/leiningen/releases/download/$LEIN_VERSION/leiningen-$LEIN_VERSION-standalone.$FILENAME_EXT && \
wget -q https://codeberg.org/leiningen/leiningen/releases/download/$LEIN_VERSION/leiningen-$LEIN_VERSION-standalone.$FILENAME_EXT.asc && \
echo "Verifying file PGP signature..." && \
gpg --batch --verify leiningen-$LEIN_VERSION-standalone.$FILENAME_EXT.asc leiningen-$LEIN_VERSION-standalone.$FILENAME_EXT && \
gpgconf --kill all && \
rm -rf "$GNUPGHOME" leiningen-$LEIN_VERSION-standalone.$FILENAME_EXT.asc && \
mkdir -p /usr/share/java && \
mv leiningen-$LEIN_VERSION-standalone.$FILENAME_EXT /usr/share/java/leiningen-$LEIN_VERSION-standalone.jar && \
apt-get purge -y --auto-remove gnupg wget

ENV PATH=$PATH:$LEIN_INSTALL
ENV LEIN_ROOT 1

# Install clojure 1.11.1 so users don't have to download it every time
RUN echo '(defproject dummy "" :dependencies [[org.clojure/clojure "1.11.1"]])' > project.clj \
  && lein deps && rm project.clj

COPY entrypoint /usr/local/bin/entrypoint

ENTRYPOINT ["entrypoint"]
CMD ["repl"]