#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

FROM openjdk:8-jdk-alpine

ARG APP_NAME
ENV WAIT_VERSION 2.7.2

ADD target/${APP_NAME}.tar.gz /opt
ADD https://github.com/ufoscout/docker-compose-wait/releases/download/$WAIT_VERSION/wait /wait
RUN chmod +x /wait
RUN mv /opt/${APP_NAME} /opt/shardingsphere-proxy-agent-jaeger
ENTRYPOINT /wait && /opt/shardingsphere-proxy-agent-jaeger/bin/start.sh && tail -f /opt/shardingsphere-proxy-agent-jaeger/logs/stdout.log
