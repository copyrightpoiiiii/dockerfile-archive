FROM bamos/ubuntu-opencv-dlib-torch:ubuntu_14.04-opencv_2.4.11-dlib_18.16-torch_2015.01.12
MAINTAINER Brandon Amos <brandon.amos.cs@gmail.com>

RUN apt-get update && apt-get install -y \
    curl \
    git \
    graphicsmagick \
    python-dev \
    python-pip \
    python-numpy \
    python-nose \
    python-scipy \
    python-sklearn \
    python-pandas \
    python-protobuf\
    wget \
    zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD . /root/src/openface
RUN cd ~/src/openface && \
    ./models/get-models.sh && \
    pip2 install -r requirements.txt && \
    python2 setup.py install && \
    pip2 install -r demos/web/requirements.txt && \
    pip2 install -r training/requirements.txt

EXPOSE 8000 9000
CMD /root/src/openface/demos/web/start-servers.sh