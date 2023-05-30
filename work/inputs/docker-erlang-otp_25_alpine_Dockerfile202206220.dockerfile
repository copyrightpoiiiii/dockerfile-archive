FROM alpine:3.16

ENV OTP_VERSION="25.0.2" \
    REBAR3_VERSION="3.18.0"

LABEL org.opencontainers.image.version=$OTP_VERSION

RUN set -xe \
 && OTP_DOWNLOAD_URL="https://github.com/erlang/otp/archive/OTP-${OTP_VERSION}.tar.gz" \
 && OTP_DOWNLOAD_SHA256="f78764c6fd504f7b264c47e469c0fcb86a01c92344dc9d625dfd42f6c3ed8224" \
 && REBAR3_DOWNLOAD_SHA256="cce1925d33240d81d0e4d2de2eef3616d4c17b0532ed004274f875e6607d25d2" \
 && apk add --no-cache --virtual .fetch-deps \
  curl \
  ca-certificates \
 && curl -fSL -o otp-src.tar.gz "$OTP_DOWNLOAD_URL" \
 && echo "$OTP_DOWNLOAD_SHA256  otp-src.tar.gz" | sha256sum -c - \
 && apk add --no-cache --virtual .build-deps \
  dpkg-dev dpkg \
  gcc \
  g++ \
  libc-dev \
  linux-headers \
  make \
  autoconf \
  ncurses-dev \
  openssl-dev \
  unixodbc-dev \
  lksctp-tools-dev \
  tar \
 && export ERL_TOP="/usr/src/otp_src_${OTP_VERSION%%@*}" \
 && mkdir -vp $ERL_TOP \
 && tar -xzf otp-src.tar.gz -C $ERL_TOP --strip-components=1 \
 && rm otp-src.tar.gz \
 && ( cd $ERL_TOP \
   && ./otp_build autoconf \
   && gnuArch="$(dpkg-architecture --query DEB_HOST_GNU_TYPE)" \
   && ./configure --build="$gnuArch" \
   && make -j$(getconf _NPROCESSORS_ONLN) \
   && make install ) \
 && rm -rf $ERL_TOP \
 && find /usr/local -regex '/usr/local/lib/erlang/\(lib/\|erts-\).*/\(man\|doc\|obj\|c_src\|emacs\|info\|examples\)' | xargs rm -rf \
 && find /usr/local -name src | xargs -r find | grep -v '\.hrl$' | xargs rm -v || true \
 && find /usr/local -name src | xargs -r find | xargs rmdir -vp || true \
 && scanelf --nobanner -E ET_EXEC -BF '%F' --recursive /usr/local | xargs -r strip --strip-all \
 && scanelf --nobanner -E ET_DYN -BF '%F' --recursive /usr/local | xargs -r strip --strip-unneeded \
 && runDeps="$( \
  scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
   | tr ',' '\n' \
   | sort -u \
   | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
 )" \
 && REBAR3_DOWNLOAD_URL="https://github.com/erlang/rebar3/archive/${REBAR3_VERSION}.tar.gz" \
 && curl -fSL -o rebar3-src.tar.gz "$REBAR3_DOWNLOAD_URL" \
 && echo "${REBAR3_DOWNLOAD_SHA256}  rebar3-src.tar.gz" | sha256sum -c - \
 && mkdir -p /usr/src/rebar3-src \
 && tar -xzf rebar3-src.tar.gz -C /usr/src/rebar3-src --strip-components=1 \
 && rm rebar3-src.tar.gz \
 && cd /usr/src/rebar3-src \
 && HOME=$PWD ./bootstrap \
 && install -v ./rebar3 /usr/local/bin/ \
 && rm -rf /usr/src/rebar3-src \
 && apk add --virtual .erlang-rundeps \
  $runDeps \
  lksctp-tools \
  ca-certificates \
 && apk del .fetch-deps .build-deps

CMD ["erl"]
