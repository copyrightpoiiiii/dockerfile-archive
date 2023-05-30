# This is an auto generated Dockerfile for gazebo:libgazebo11
# generated from docker_images/create_gzclient_image.Dockerfile.em
FROM gazebo:gzserver11-bionic

# install gazebo packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgazebo11-dev=11.10.1-1* \
    && rm -rf /var/lib/apt/lists/*
