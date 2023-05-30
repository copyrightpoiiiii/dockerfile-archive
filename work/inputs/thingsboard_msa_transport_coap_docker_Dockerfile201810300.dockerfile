#
# Copyright © 2016-2018 The Thingsboard Authors
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
#

FROM openjdk:8-jdk

COPY logback.xml ${pkg.name}.conf start-tb-coap-transport.sh ${pkg.name}.deb /tmp/

RUN chmod a+x /tmp/*.sh \
    && mv /tmp/start-tb-coap-transport.sh /usr/bin

RUN dpkg -i /tmp/${pkg.name}.deb

RUN update-rc.d ${pkg.name} disable

RUN mv /tmp/logback.xml ${pkg.installFolder}/conf \
    && mv /tmp/${pkg.name}.conf ${pkg.installFolder}/conf

CMD ["start-tb-coap-transport.sh"]
