# docker build --file $PROJECT_DIR/docker/development.Dockerfile --tag typesense/typesense-development:latest $PROJECT_DIR/docker
# 
# $ docker push typesense/typesense-development:latest

FROM typesense/ubuntu-10.04-gcc:6.5.0

ENV PATH /usr/local/gcc-6.4.0/bin/:$PATH
ENV LD_LIBRARY_PATH /usr/local/gcc-6.4.0/lib64

RUN apt-get install -y python-software-properties \
 && add-apt-repository ppa:git-core/ppa \
 && apt-get update \
 && apt-get install -y \
 zlib1g-dev \
 liblist-compare-perl \
 libidn11 \
 git

ADD https://cmake.org/files/v3.3/cmake-3.3.2-Linux-x86_64.tar.gz /opt/
RUN tar -C /opt -xvzf /opt/cmake-3.3.2-Linux-x86_64.tar.gz
RUN cp -r /opt/cmake-3.3.2-Linux-x86_64/* /usr

ADD https://launchpad.net/ubuntu/+archive/primary/+files/snappy_1.1.3.orig.tar.gz /opt/
RUN tar -C /opt -xf /opt/snappy_1.1.3.orig.tar.gz
RUN mkdir /opt/snappy-1.1.3/build && cd /opt/snappy-1.1.3/build && ../configure && make && make install

ADD https://openssl.org/source/openssl-1.0.2k.tar.gz /opt/
RUN tar -C /opt -xvzf /opt/openssl-1.0.2k.tar.gz
RUN cd /opt/openssl-1.0.2k && sh ./config --prefix=/usr --openssldir=/usr zlib-dynamic
RUN make -C /opt/openssl-1.0.2k depend
RUN make -C /opt/openssl-1.0.2k -j4
RUN make -C /opt/openssl-1.0.2k install

ADD https://github.com/curl/curl/releases/download/curl-7_55_1/curl-7.55.1.tar.bz2 /opt/
RUN tar -C /opt -xf /opt/curl-7.55.1.tar.bz2
RUN cd /opt/curl-7.55.1 && ./configure && make && make install

ENV CC /usr/local/gcc-6.4.0/bin/gcc
ENV CXX /usr/local/gcc-6.4.0/bin/g++
