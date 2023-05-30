# Run yubico-piv-tool in a container
#
# docker run --rm -it \
#  --device /dev/bus/usb \
#  --device /dev/usb
# --name yubico-piv-tool \
# jess/yubico-piv-tool
#
FROM debian:sid
MAINTAINER Jessica Frazelle <jess@docker.com>

RUN apt-get update && apt-get install -y \
 usbutils \
 yubico-piv-tool \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /root/

CMD [ "yubico-piv-tool", "--help" ]
