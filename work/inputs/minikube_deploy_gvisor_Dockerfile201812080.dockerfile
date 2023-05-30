# Copyright 2016 The Kubernetes Authors All rights reserved.
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

FROM ubuntu:18.04
RUN apt-get update && \
    apt-get install -y kmod gcc wget xz-utils libc6-dev bc libelf-dev bison flex openssl libssl-dev libidn2-0 sudo libcap2 && \
    rm -rf /var/lib/apt/lists/*
COPY out/gvisor-addon /gvisor-addon
CMD ["/gvisor-addon"]
