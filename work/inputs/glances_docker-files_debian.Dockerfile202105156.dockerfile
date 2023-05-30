#
# Glances Dockerfile (based on Debian)
#
# https://github.com/nicolargo/glances
#

ARG ARCH
FROM ${ARCH}python:3.9-slim-buster as build

# Install package
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  python3-dev \
  curl \
  gcc \
  lm-sensors \
  wireless-tools \
  iputils-ping && \
  apt-get clean && rm -rf /var/lib/apt/lists/*

# Force rebuild otherwise it could be cached without rerun
ARG VCS_REF
RUN pip3 install --no-cache-dir --user glances[all]

FROM build as additional-packages

COPY *requirements.txt .

RUN CASS_DRIVER_NO_CYTHON=1 pip3 install --no-cache-dir --user -r optional-requirements.txt


#Create running image without any building dependency
FROM ${ARCH}python:3.9-slim-buster as minimal

RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  curl              \
  lm-sensors        \
  wireless-tools    \
  iputils-ping && \
  apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=build /root/.local/bin /usr/local/bin/
COPY --from=build /root/.local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages/

# EXPOSE PORT (XMLRPC / WebUI)
EXPOSE 61209 61208

# Define default command.
CMD python3 -m glances -C /glances/conf/glances.conf $GLANCES_OPT


FROM minimal as full

COPY --from=additional-packages /root/.local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages/
