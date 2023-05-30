#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM alpine:3.16

ENV JULIA_PATH /usr/local/julia
ENV PATH $JULIA_PATH/bin:$PATH

# https://julialang.org/juliareleases.asc
# Julia (Binary signing key) <buildbot@julialang.org>
ENV JULIA_GPG 3673DF529D9049477F76B37566E3C7DC03D6E495

# https://julialang.org/downloads/
ENV JULIA_VERSION 1.6.6

RUN set -eux; \
 \
 apk add --no-cache --virtual .fetch-deps gnupg; \
 \
# https://julialang.org/downloads/#julia-command-line-version
# https://julialang-s3.julialang.org/bin/checksums/julia-1.6.6.sha256
 arch="$(apk --print-arch)"; \
 case "$arch" in \
  'x86_64') \
   url='https://julialang-s3.julialang.org/bin/musl/x64/1.6/julia-1.6.6-musl-x86_64.tar.gz'; \
   sha256='e46870ee6b6a1af18046584b9121d8fdd69c0632c9625aec5998c65040b8b701'; \
   ;; \
  *) \
   echo >&2 "error: current architecture ($arch) does not have a corresponding Julia binary release"; \
   exit 1; \
   ;; \
 esac; \
 \
 wget -O julia.tar.gz.asc "$url.asc"; \
 wget -O julia.tar.gz "$url"; \
 \
 echo "$sha256 *julia.tar.gz" | sha256sum -w -c -; \
 \
 export GNUPGHOME="$(mktemp -d)"; \
 gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$JULIA_GPG"; \
 gpg --batch --verify julia.tar.gz.asc julia.tar.gz; \
 command -v gpgconf > /dev/null && gpgconf --kill all; \
 rm -rf "$GNUPGHOME" julia.tar.gz.asc; \
 \
 mkdir "$JULIA_PATH"; \
 tar -xzf julia.tar.gz -C "$JULIA_PATH" --strip-components 1; \
 rm julia.tar.gz; \
 \
 apk del --no-network .fetch-deps; \
 \
# smoke test
 julia --version

CMD ["julia"]