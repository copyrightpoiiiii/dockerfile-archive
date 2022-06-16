#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM alpine:3.16

RUN apk add --no-cache java-cacerts

ENV JAVA_HOME /opt/openjdk-19
ENV PATH $JAVA_HOME/bin:$PATH

# https://jdk.java.net/
# >
# > Java Development Kit builds, from Oracle
# >
ENV JAVA_VERSION 19-ea+5
# "For Alpine Linux, builds are produced on a reduced schedule and may not be in sync with the other platforms."

RUN set -eux; \
 \
 arch="$(apk --print-arch)"; \
 case "$arch" in \
  'x86_64') \
   downloadUrl='https://download.java.net/java/early_access/alpine/5/binaries/openjdk-19-ea+5_linux-x64-musl_bin.tar.gz'; \
   downloadSha256='0ee67a41fe97341f131bd4f065ed6092d55c15de5f00f8ba1e57d21eefb2c787'; \
   ;; \
  *) echo >&2 "error: unsupported architecture: '$arch'"; exit 1 ;; \
 esac; \
 \
 wget -O openjdk.tgz "$downloadUrl"; \
 echo "$downloadSha256 *openjdk.tgz" | sha256sum -c -; \
 \
 mkdir -p "$JAVA_HOME"; \
 tar --extract \
  --file openjdk.tgz \
  --directory "$JAVA_HOME" \
  --strip-components 1 \
  --no-same-owner \
 ; \
 rm openjdk.tgz*; \
 \
 rm -rf "$JAVA_HOME/lib/security/cacerts"; \
# see "java-cacerts" package installed above (which maintains "/etc/ssl/certs/java/cacerts" for us)
 ln -sT /etc/ssl/certs/java/cacerts "$JAVA_HOME/lib/security/cacerts"; \
 \
# https://github.com/docker-library/openjdk/issues/212#issuecomment-420979840
# https://openjdk.java.net/jeps/341
 java -Xshare:dump; \
 \
# basic smoke test
 fileEncoding="$(echo 'System.out.println(System.getProperty("file.encoding"))' | jshell -s -)"; [ "$fileEncoding" = 'UTF-8' ]; rm -rf ~/.java; \
 javac --version; \
 java --version

# "jshell" is an interactive REPL for Java (see https://en.wikipedia.org/wiki/JShell)
CMD ["jshell"]
