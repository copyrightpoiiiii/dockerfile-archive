#
# Copyright © 2016-2021 The Thingsboard Authors
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

FROM thingsboard/base

ARG TARGETPLATFORM

COPY start-js-executor.sh ${pkg.name}.deb ${pkg.name}-arm64.deb /tmp/

RUN chmod a+x /tmp/*.sh \
    && mv /tmp/start-js-executor.sh /usr/bin

RUN if [ "$TARGETPLATFORM" = "linux/arm64" ]; \
    then yes | dpkg -i /tmp/${pkg.name}-arm64.deb; \
    else yes | dpkg -i /tmp/${pkg.name}.deb; \
    fi
RUN rm /tmp/${pkg.name}.deb
RUN rm /tmp/${pkg.name}-arm64.deb

RUN systemctl --no-reload disable --now ${pkg.name}.service > /dev/null 2>&1 || :

RUN chmod 555 ${pkg.installFolder}/bin/${pkg.name}

USER ${pkg.user}

CMD ["start-js-executor.sh"]