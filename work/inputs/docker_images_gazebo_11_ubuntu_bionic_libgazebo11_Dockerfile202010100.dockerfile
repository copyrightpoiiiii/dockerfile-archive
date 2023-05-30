# This is an auto generated Dockerfile for gazebo:libgazebo11
# generated from docker_images/create_gzclient_image.Dockerfile.em
FROM gazebo:gzserver11-bionic
# label gazebo packages
LABEL sha256.libgazebo11-dev=41f50bd73f610ddaca333daa89ed3db2decd65ded2e79d92c2caee90eb59e7ec

# install gazebo packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgazebo11-dev=11.2.0-1* \
    && rm -rf /var/lib/apt/lists/*
