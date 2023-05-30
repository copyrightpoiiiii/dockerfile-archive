# docker build --file ./docker/development-arm.Dockerfile --tag typesense/typesense-development-arm:03-DEC-2021-1 ./docker
# 
# $ docker push typesense/typesense-development-arm:03-DEC-2021-1

FROM gcc:10.3.0-buster

RUN apt-get update && \
    apt-get install -y software-properties-common \
    zlib1g-dev \
    liblist-compare-perl \
    git

ADD https://ftp.gnu.org/gnu/binutils/binutils-2.36.tar.xz /opt/binutils-2.36.tar.xz
RUN tar -C /opt -xf /opt/binutils-2.36.tar.xz
RUN cd /opt/binutils-2.36 && ./configure --prefix=/usr && make tooldir=/usr && make check && \
    make -j8 tooldir=/usr install && cp include/libiberty.h /usr/include

ADD https://github.com/Kitware/CMake/releases/download/v3.22.0/cmake-3.22.0-linux-aarch64.tar.gz /opt/cmake-3.22.0-linux-aarch64.tar.gz
RUN tar -C /opt -xvzf /opt/cmake-3.22.0-linux-aarch64.tar.gz
RUN cp -r /opt/cmake-3.22.0-linux-aarch64/* /usr

ADD https://launchpad.net/ubuntu/+archive/primary/+files/snappy_1.1.3.orig.tar.gz /opt/snappy_1.1.3.orig.tar.gz
RUN tar -C /opt -xf /opt/snappy_1.1.3.orig.tar.gz
RUN mkdir -p /opt/snappy-1.1.3/build && cd /opt/snappy-1.1.3/build && ../configure && make -j8 && make install

ADD https://github.com/unicode-org/icu/releases/download/release-68-2/icu4c-68_2-src.tgz /opt/icu4c-68_2-src.tgz
RUN tar -C /opt -xf /opt/icu4c-68_2-src.tgz
RUN cd /opt/icu/source && echo "#define U_DISABLE_RENAMING 1" >> common/unicode/uconfig.h && \
    echo "#define U_STATIC_IMPLEMENTATION 1" >> common/unicode/uconfig.h && \
    echo "#define U_USING_ICU_NAMESPACE 0" >> common/unicode/uconfig.h
RUN cd /opt/icu/source && ./runConfigureICU Linux --disable-samples --disable-tests --enable-static \
    --disable-shared --disable-renaming && make -j8 && make install

ADD https://openssl.org/source/openssl-1.1.1l.tar.gz /opt/openssl-1.1.1l.tar.gz
RUN tar -C /opt -xvzf /opt/openssl-1.1.1l.tar.gz
RUN cd /opt/openssl-1.1.1l && sh ./config --prefix=/usr/local --openssldir=/usr/local zlib
RUN make -C /opt/openssl-1.1.1l depend
RUN make -C /opt/openssl-1.1.1l -j8
RUN make -C /opt/openssl-1.1.1l install

ADD https://github.com/curl/curl/releases/download/curl-7_78_0/curl-7.78.0.tar.gz /opt/curl-7.78.0.tar.gz
RUN tar -C /opt -xf /opt/curl-7.78.0.tar.gz
RUN cd /opt/curl-7.78.0 && LIBS="-ldl -lpthread" ./configure --disable-shared --with-ssl=/usr/local \
--without-ca-bundle --without-libssh2 --without-gssapi --disable-ldap --without-libidn2 --without-librtmp \
--without-zstd --without-ca-path && make -j8 && make install && rm -rf /usr/local/lib/*.so*

ADD https://github.com/gflags/gflags/archive/v2.2.2.tar.gz /opt/gflags-2.2.2.tar.gz
RUN tar -C /opt -xf /opt/gflags-2.2.2.tar.gz
RUN cd /opt/gflags-2.2.2 && cmake . -DBUILD_SHARED_LIBS=OFF && make -j8 && make install && rm -rf /usr/local/lib/*.so*

RUN apt-get install -y autoconf automake libtool unzip
RUN rm -rf /usr/local/lib/*.so*

ADD https://github.com/protocolbuffers/protobuf/releases/download/v3.11.4/protobuf-cpp-3.11.4.tar.gz /opt/protobuf-cpp-3.11.4.tar.gz
RUN tar -C /opt -xf /opt/protobuf-cpp-3.11.4.tar.gz && chown -R root:root /opt/protobuf-3.11.4
RUN cd /opt/protobuf-3.11.4 && ./configure --disable-shared && make -j8 && make check && make install && rm -rf /usr/local/lib/*.so*

ADD https://github.com/google/leveldb/archive/1.22.tar.gz /opt/leveldb-1.22.tar.gz
RUN tar -C /opt -xf /opt/leveldb-1.22.tar.gz
RUN mkdir -p /opt/leveldb-1.22/build && cd /opt/leveldb-1.22/build && cmake -DCMAKE_BUILD_TYPE=Release .. && \
    cmake --build . && make install && rm -rf /usr/local/lib/*.so*

ADD https://github.com/google/glog/archive/0a2e593.tar.gz /opt/glog-0a2e593.tar.gz
RUN tar -C /opt -xf /opt/glog-0a2e593.tar.gz
RUN mkdir -p /opt/glog-0a2e5931bd5ff22fd3bf8999eb8ce776f159cda6/bld && \
    cd /opt/glog-0a2e5931bd5ff22fd3bf8999eb8ce776f159cda6/bld && \
    cmake -DBUILD_TESTING=0 -DWITH_GFLAGS=ON -DWITH_TLS=OFF -DWITH_UNWIND=OFF .. && \
    cmake --build . && make install && rm -rf /usr/local/lib/*.so*

ADD https://sourceware.org/elfutils/ftp/0.182/elfutils-0.182.tar.bz2 /opt/elfutils-0.182.tar.bz2
RUN tar -C /opt -xf /opt/elfutils-0.182.tar.bz2
RUN cd /opt/elfutils-0.182 && ./configure --disable-libdebuginfod --disable-debuginfod --without-lzma --without-bzlib && \
make -j8 && make install && rm -rf /usr/local/lib/*.so*

ADD https://github.com/typesense/incubator-brpc/archive/7d4d601.tar.gz /opt/brpc-7d4d601.tar.gz
RUN tar -C /opt -xf /opt/brpc-7d4d601.tar.gz
COPY patches/brpc_cmakelists.txt /opt/incubator-brpc-7d4d60126bcc0aefbef9fa8b3bc784bff18540be/src/CMakeLists.txt
RUN chown root:root /opt/incubator-brpc-7d4d60126bcc0aefbef9fa8b3bc784bff18540be/src/CMakeLists.txt
RUN mkdir -p /opt/incubator-brpc-7d4d60126bcc0aefbef9fa8b3bc784bff18540be/bld && \
    cd /opt/incubator-brpc-7d4d60126bcc0aefbef9fa8b3bc784bff18540be/bld && \
    cmake -DWITH_DEBUG_SYMBOLS=OFF -DWITH_GLOG=ON .. && \
    make -j8 && make install && rm -rf /usr/local/lib/*.so* && \
    rm -rf /opt/incubator-brpc-7d4d60126bcc0aefbef9fa8b3bc784bff18540be/bld/output/bin

ADD https://github.com/typesense/braft/archive/938eeb5.tar.gz /opt/braft-938eeb5.tar.gz
RUN tar -C /opt -xf /opt/braft-938eeb5.tar.gz
COPY patches/braft_cmakelists.txt /opt/braft-938eeb5f67dd9ef592f7ec9bd37b9b822980a2c5/src/CMakeLists.txt
RUN chown root:root /opt/braft-938eeb5f67dd9ef592f7ec9bd37b9b822980a2c5/src/CMakeLists.txt
RUN mkdir -p /opt/braft-938eeb5f67dd9ef592f7ec9bd37b9b822980a2c5/bld && \
    cd /opt/braft-938eeb5f67dd9ef592f7ec9bd37b9b822980a2c5/bld && \
    cmake -DWITH_DEBUG_SYMBOLS=ON -DBRPC_WITH_GLOG=ON .. && make -j4 && \
    make install && rm -rf /usr/local/lib/*.so* && \
    rm -rf /opt/braft-938eeb5f67dd9ef592f7ec9bd37b9b822980a2c5/bld/output/bin
