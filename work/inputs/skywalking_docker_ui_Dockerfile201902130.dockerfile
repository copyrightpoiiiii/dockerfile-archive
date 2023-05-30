# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM openjdk:8-jre-alpine

ENV DIST_NAME=skywalking \
    JAVA_OPTS=" -Xms256M "

# Install required packages
RUN apk add --no-cache \
    bash

COPY "$DIST_NAME.tar.gz" /

RUN set -ex; \
    tar -xzf "$DIST_NAME.tar.gz"; \
    rm -rf "$DIST_NAME.tar.gz"; rm -rf "$DIST_NAME/config"; \
    rm -rf "$DIST_NAME/bin"; rm -rf "$DIST_NAME/oap-libs"; rm -rf "$DIST_NAME/agent";

WORKDIR $DIST_NAME

COPY docker-entrypoint.sh .
COPY logback.xml webapp/

EXPOSE 8080

ENTRYPOINT ["sh", "docker-entrypoint.sh"]
