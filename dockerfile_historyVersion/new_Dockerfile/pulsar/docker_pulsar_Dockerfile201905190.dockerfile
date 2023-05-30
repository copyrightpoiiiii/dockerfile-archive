#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

# First create a stage with just the Pulsar tarball and scripts
FROM busybox as pulsar

ARG PULSAR_TARBALL

ADD ${PULSAR_TARBALL} /
RUN mv /apache-pulsar-* /pulsar

COPY scripts/apply-config-from-env.py /pulsar/bin
COPY scripts/gen-yml-from-env.py /pulsar/bin
COPY scripts/generate-zookeeper-config.sh /pulsar/bin
COPY scripts/pulsar-zookeeper-ruok.sh /pulsar/bin
COPY scripts/watch-znode.py /pulsar/bin
COPY scripts/set_python_version.sh /pulsar/bin
COPY scripts/install-pulsar-client-27.sh /pulsar/bin
COPY scripts/install-pulsar-client-35.sh /pulsar/bin


### Create 2nd stage from OpenJDK image
### and add Python dependencies (for Pulsar functions)

FROM openjdk:8-jdk-slim
COPY --from=pulsar /pulsar /pulsar

# Install some utilities
RUN apt-get update \
     && apt-get install -y netcat dnsutils \
                 python2.7 python-setuptools \
                 python3 python3-setuptools \
     && apt-get clean \
     && rm -rf /var/lib/apt/lists/*

RUN easy_install pip
RUN pip install kazoo pyyaml
RUN easy_install3 pip

ADD target/python-client/ /pulsar/pulsar-client
RUN /pulsar/bin/install-pulsar-client-27.sh
RUN /pulsar/bin/install-pulsar-client-35.sh
RUN echo networkaddress.cache.ttl=1 >> $JAVA_HOME/jre/lib/security/java.security

WORKDIR /pulsar

VOLUME  ["/pulsar/conf", "/pulsar/data"]

ENV PULSAR_ROOT_LOGGER=INFO,CONSOLE
