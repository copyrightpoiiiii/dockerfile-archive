# This is an auto generated Dockerfile for gazebo:libgazebo11
# generated from docker_images/create_gzclient_image.Dockerfile.em
FROM gazebo:gzserver11-bionic
# install gazebo packages
RUN apt-get update && apt-get install -q -y \
    libgazebo11-dev=11.0.0-1* \
    && rm -rf /var/lib/apt/lists/*
