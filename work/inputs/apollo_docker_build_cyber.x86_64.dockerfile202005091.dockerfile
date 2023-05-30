ARG BASE_IMAGE=nvidia/cuda:10.2-cudnn7-devel-ubuntu18.04
ARG GEOLOC
FROM ${BASE_IMAGE}

LABEL version="1.2"

ENV DEBIAN_FRONTEND=noninteractive

COPY installers /tmp/installers

# Pre-downloaded tarballs
COPY archive /tmp/archive

RUN bash /tmp/installers/install_minimal_environment.sh "${GEOLOC}"
RUN bash /tmp/installers/install_cyber_dependencies.sh
RUN bash /tmp/installers/install_cmake.sh
RUN bash /tmp/installers/install_protobuf.sh
RUN bash /tmp/installers/install_gflags_glog.sh
RUN bash /tmp/installers/install_fast-rtps.sh
RUN bash /tmp/installers/install_poco.sh
RUN bash /tmp/installers/install_visualizer_dependencies.sh

RUN bash /tmp/installers/install_bazel.sh && \
    bash /tmp/installers/install_user.sh && \
    bash /tmp/installers/post_install.sh

WORKDIR /apollo
USER apollo