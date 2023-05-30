FROM centos:8
ENV VERSION 1
#install dependencies
RUN yum update -y && \
    yum install -y epel-release  && \
    yum --enablerepo=extras install -y which git autoconf automake libtool make bzip2 && \
    yum --enablerepo=extras install -y  graphviz bzip2-devel openssl-devel gmp-devel  && \
    yum --enablerepo=extras install -y  file libusbx-devel && \
    yum --enablerepo=extras install -y libcurl-devel patch vim-common jq && \
    yum install -y python3 python3-devel clang llvm-devel llvm-static procps-ng util-linux sudo libstdc++
RUN dnf install -y  https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
    dnf group install -y  "Development Tools" && \
    dnf --enablerepo=PowerTools install -y doxygen ocaml
# cmake3.18.0
RUN curl -LO https://github.com/Kitware/CMake/releases/download/v3.18.0/cmake-3.18.0.tar.gz && \
    tar -xzf cmake-3.18.0.tar.gz && \
    cd cmake-3.18.0 && \
    ./bootstrap --prefix=/usr/local && \
    make -j$(nproc) && make install && \
    rm -rf cmake-3.18.0.tar.gz cmake-3.18.2
# build boost
RUN curl -LO https://dl.bintray.com/boostorg/release/1.72.0/source/boost_1_72_0.tar.bz2 && \
    tar -xjf boost_1_72_0.tar.bz2 && \
    cd boost_1_72_0 && \
    ./bootstrap.sh --prefix=/usr/local && \
    ./b2 --with-iostreams --with-date_time --with-filesystem --with-system --with-program_options --with-chrono --with-test -q -j$(nproc) install && \
    cd / && \
    rm -rf boost_1_72_0.tar.bz2 /boost_1_72_0
# install nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.0/install.sh | bash
# load nvm in non-interactive shells
RUN cp ~/.bashrc ~/.bashrc.bak && \
    cat ~/.bashrc.bak | tail -3 > ~/.bashrc && \
    cat ~/.bashrc.bak | head -n '-3' >> ~/.bashrc && \
    rm ~/.bashrc.bak
# install node 10
RUN bash -c '. ~/.bashrc; nvm install --lts=dubnium' && \
    ln -s "/root/.nvm/versions/node/$(ls -p /root/.nvm/versions/node | sort -Vr | head -1)bin/node" /usr/local/bin/node
RUN yum install -y nodejs
