#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM debian:bullseye-slim

RUN set -eux; \
 apt-get update; \
 apt-get install -y --no-install-recommends ca-certificates; \
 rm -rf /var/lib/apt/lists/*

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8

# ensure local pypy3 is preferred over distribution pypy3
ENV PATH /opt/pypy/bin:$PATH

ENV PYPY_VERSION 7.3.6

RUN set -eux; \
 \
 dpkgArch="$(dpkg --print-architecture)"; \
 case "${dpkgArch##*-}" in \
  'amd64') \
   url='https://downloads.python.org/pypy/pypy3.7-v7.3.6-linux64.tar.bz2'; \
   sha256='c41d07063b1d002a91ad2a0763b4baaca2b306ec635889c2e4826e706cc7f9ca'; \
   ;; \
  'arm64') \
   url='https://downloads.python.org/pypy/pypy3.7-v7.3.6-aarch64.tar.bz2'; \
   sha256='d446b6987eeaa03d706603863e83d6b99df69232cf1e06d3ee5706add6a84cd6'; \
   ;; \
  'i386') \
   url='https://downloads.python.org/pypy/pypy3.7-v7.3.6-linux32.tar.bz2'; \
   sha256='459e77c845b31fa9367f7b1b1122155f0ba7888b1d4ce4455c35d2111eeeb275'; \
   ;; \
  's390x') \
   url='https://downloads.python.org/pypy/pypy3.7-v7.3.6-s390x.tar.bz2'; \
   sha256='3659bf96a177a53426ffc38d3619c6ee307e600c80e924edc9cee604680c141d'; \
   ;; \
  *) echo >&2 "error: current architecture ($dpkgArch) does not have a corresponding PyPy $PYPY_VERSION binary release"; exit 1 ;; \
 esac; \
 \
 savedAptMark="$(apt-mark showmanual)"; \
 apt-get update; \
 apt-get install -y --no-install-recommends \
  bzip2 \
  wget \
# sometimes "pypy3" itself is linked against libexpat1 / libncurses5, sometimes they're ".so" files in "/opt/pypy/lib_pypy"
  libexpat1 \
  libncurses5 \
# (so we'll add them temporarily, then use "ldd" later to determine which to keep based on usage per architecture)
 ; \
 \
 wget -O pypy.tar.bz2 "$url" --progress=dot:giga; \
 echo "$sha256 *pypy.tar.bz2" | sha256sum --check --strict -; \
 mkdir /opt/pypy; \
 tar -xjC /opt/pypy --strip-components=1 -f pypy.tar.bz2; \
 find /opt/pypy/lib-python -depth -type d -a \( -name test -o -name tests \) -exec rm -rf '{}' +; \
 rm pypy.tar.bz2; \
 \
 ln -sv '/opt/pypy/bin/pypy3' /usr/local/bin/; \
 \
# smoke test
 pypy3 --version; \
 \
# on pypy3, rebuild ffi bits for compatibility with Debian Stretch+
 cd /opt/pypy/lib_pypy; \
# https://github.com/docker-library/pypy/issues/24#issuecomment-409408657
 if [ -f _ssl_build.py ]; then \
  apt-get install -y --no-install-recommends gcc libc6-dev libssl-dev; \
  pypy3 _ssl_build.py; \
 fi; \
# https://github.com/docker-library/pypy/issues/42
 if [ -f _lzma_build.py ]; then \
  apt-get install -y --no-install-recommends gcc libc6-dev liblzma-dev; \
  pypy3 _lzma_build.py; \
 fi; \
# TODO rebuild other cffi modules here too? (other _*_build.py files)
 \
 apt-mark auto '.*' > /dev/null; \
 [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark > /dev/null; \
 find /opt/pypy -type f -executable -exec ldd '{}' ';' \
  | awk '/=>/ { print $(NF-1) }' \
  | sort -u \
  | xargs -r dpkg-query --search \
  | cut -d: -f1 \
  | sort -u \
  | xargs -r apt-mark manual \
 ; \
 apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
 rm -rf /var/lib/apt/lists/*; \
# smoke test again, to be sure
 pypy3 --version; \
 \
 find /opt/pypy -depth \
  \( \
   \( -type d -a \( -name test -o -name tests \) \) \
   -o \
   \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
  \) -exec rm -rf '{}' +

# https://github.com/pypa/get-pip
ENV PYTHON_GET_PIP_URL https://github.com/pypa/get-pip/raw/3843bff3a0a61da5b63ea0b7d34794c5c51a2f11/get-pip.py
ENV PYTHON_GET_PIP_SHA256 95c5ee602b2f3cc50ae053d716c3c89bea62c58568f64d7d25924d399b2d5218

RUN set -ex; \
 apt-get update; \
 apt-get install -y --no-install-recommends wget; \
 rm -rf /var/lib/apt/lists/*; \
 \
 wget -O get-pip.py "$PYTHON_GET_PIP_URL"; \
 echo "$PYTHON_GET_PIP_SHA256 *get-pip.py" | sha256sum --check --strict -; \
 \
 pipVersion="$(pypy3 -c 'import ensurepip; print(ensurepip._PIP_VERSION)')"; \
 setuptoolsVersion="$(pypy3 -c 'import ensurepip; print(ensurepip._SETUPTOOLS_VERSION)')"; \
 \
 pypy3 get-pip.py \
  --disable-pip-version-check \
  --no-cache-dir \
  "pip == $pipVersion" \
  "setuptools == $setuptoolsVersion" \
 ; \
 apt-get purge -y --auto-remove wget; \
# smoke test
 pip --version; \
 \
 find /opt/pypy -depth \
  \( \
   \( -type d -a \( -name test -o -name tests \) \) \
   -o \
   \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
  \) -exec rm -rf '{}' +; \
 rm -f get-pip.py

CMD ["pypy3"]