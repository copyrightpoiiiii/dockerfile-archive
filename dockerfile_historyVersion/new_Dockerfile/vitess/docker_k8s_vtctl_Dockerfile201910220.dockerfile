# Copyright 2019 The Vitess Authors.
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

FROM vitess/k8s AS k8s

FROM debian:stretch-slim

# Set up Vitess environment (just enough to run pre-built Go binaries)
ENV VTROOT /vt

# Prepare directory structure.
RUN mkdir -p /vt/bin && mkdir -p /vtdataroot

# Copy certs to allow https calls
COPY --from=k8s /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

# Copy binaries
COPY --from=k8s /vt/bin/vtctl /vt/bin/

# add vitess user/group and add permissions
RUN groupadd -r --gid 2000 vitess && \
   useradd -r -g vitess --uid 1000 vitess && \
   chown -R vitess:vitess /vt && \
   chown -R vitess:vitess /vtdataroot
