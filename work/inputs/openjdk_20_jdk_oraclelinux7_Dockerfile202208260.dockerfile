#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM oraclelinux:7-slim

RUN set -eux; \
# https://unix.stackexchange.com/a/477127/153467
 yum install -y --setopt=skip_missing_names_on_install=False \
  gzip \
  tar \
  \
# jlink --strip-debug on 13+ needs objcopy: https://github.com/docker-library/openjdk/issues/351
# Error: java.io.IOException: Cannot run program "objcopy": error=2, No such file or directory
  binutils \
# java.lang.UnsatisfiedLinkError: /usr/java/openjdk-12/lib/libfontmanager.so: libfreetype.so.6: cannot open shared object file: No such file or directory
# https://github.com/docker-library/openjdk/pull/235#issuecomment-424466077
  freetype fontconfig \
 ; \
 rm -rf /var/cache/yum

ENV JAVA_HOME /usr/java/openjdk-20
ENV PATH $JAVA_HOME/bin:$PATH

# Default to UTF-8 file.encoding
ENV LANG en_US.UTF-8

# https://jdk.java.net/
# >
# > Java Development Kit builds, from Oracle
# >
ENV JAVA_VERSION 20-ea+12

RUN set -eux; \
 \
 arch="$(objdump="$(command -v objdump)" && objdump --file-headers "$objdump" | awk -F '[:,]+[[:space:]]+' '$1 == "architecture" { print $2 }')"; \
 case "$arch" in \
  'i386:x86-64') \
   downloadUrl='https://download.java.net/java/early_access/jdk20/12/GPL/openjdk-20-ea+12_linux-x64_bin.tar.gz'; \
   downloadSha256='c15feea1a5fa60e2d919fe6f1d30f0c1ae790c975e58e9e5e3681523bef0fbb7'; \
   ;; \
  'aarch64') \
   downloadUrl='https://download.java.net/java/early_access/jdk20/12/GPL/openjdk-20-ea+12_linux-aarch64_bin.tar.gz'; \
   downloadSha256='30ddc30c2c4a6058212c829ca65f18bf21f7b97a88d08eb084840a355372c865'; \
   ;; \
  *) echo >&2 "error: unsupported architecture: '$arch'"; exit 1 ;; \
 esac; \
 \
 curl -fL -o openjdk.tgz "$downloadUrl"; \
 echo "$downloadSha256 *openjdk.tgz" | sha256sum --strict --check -; \
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
# see "update-ca-trust" script which creates/maintains this cacerts bundle
 ln -sT /etc/pki/ca-trust/extracted/java/cacerts "$JAVA_HOME/lib/security/cacerts"; \
 \
# https://github.com/oracle/docker-images/blob/a56e0d1ed968ff669d2e2ba8a1483d0f3acc80c0/OracleJava/java-8/Dockerfile#L17-L19
 ln -sfT "$JAVA_HOME" /usr/java/default; \
 ln -sfT "$JAVA_HOME" /usr/java/latest; \
 for bin in "$JAVA_HOME/bin/"*; do \
  base="$(basename "$bin")"; \
  [ ! -e "/usr/bin/$base" ]; \
  alternatives --install "/usr/bin/$base" "$base" "$bin" 20000; \
 done; \
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
