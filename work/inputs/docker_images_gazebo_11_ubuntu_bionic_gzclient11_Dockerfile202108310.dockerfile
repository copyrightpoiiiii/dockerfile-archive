# This is an auto generated Dockerfile for gazebo:gzclient11
# generated from docker_images/create_gzclient_image.Dockerfile.em
FROM gazebo:gzserver11-bionic

# install packages
RUN apt-get update && apt-get install -q -y --no-install-recommends \
    binutils \
    mesa-utils \
    module-init-tools \
    x-window-system \
    && rm -rf /var/lib/apt/lists/*

# install gazebo packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    gazebo11=11.8.1-1* \
    && rm -rf /var/lib/apt/lists/*