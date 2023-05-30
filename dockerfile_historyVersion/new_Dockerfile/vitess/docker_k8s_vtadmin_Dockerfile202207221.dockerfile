# Copyright 2022 The Vitess Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ARG VT_BASE_VER=latest
ARG DEBIAN_VER=bullseye-slim

FROM vitess/k8s:${VT_BASE_VER} AS k8s

FROM node:16-${DEBIAN_VER} as node

# Set up Vitess environment (just enough to run pre-built Go binaries)
ENV VTROOT /vt

# Prepare directory structure.
RUN mkdir -p /vt/bin && \
   mkdir -p /vt/web && mkdir -p /vtdataroot

# Copy binaries
COPY --from=k8s /vt/bin/vtadmin /vt/bin/

# Copy certs to allow https calls
COPY --from=k8s /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

# copy web admin files
COPY --from=k8s /vt/web/vtadmin /vt/web/vtadmin

# install/build/clean web dependencies
RUN npm --prefix /vt/web/vtadmin ci && \
    npm run --prefix /vt/web/vtadmin build


FROM nginxinc/nginx-unprivileged:1.22-alpine AS nginx

ENV VTADMIN_WEB_PORT=14201

COPY --from=node /vt/web/vtadmin/build /var/www/
COPY default.conf /etc/nginx/templates/default.conf.template

USER nginx

CMD ["nginx", "-g", "daemon off;"]