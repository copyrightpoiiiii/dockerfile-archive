# A Dockerfile that sets up a full Gym install with test dependencies
ARG PYTHON_VER
FROM python:$PYTHON_VER
RUN apt-get -y update && apt-get install -y unzip libglu1-mesa-dev libgl1-mesa-dev libosmesa6-dev xvfb patchelf ffmpeg
RUN \ 
# Download mujoco
    mkdir /root/.mujoco && \
    cd /root/.mujoco  && \
    curl -O https://www.roboti.us/download/mjpro150_linux.zip  && \
    unzip mjpro150_linux.zip && \
    curl -O https://www.roboti.us/download/mujoco200_linux.zip && \
    unzip mujoco200_linux.zip && \
    mv mujoco200_linux mujoco200

ARG MUJOCO_KEY
ARG PYTHON_VER
ENV MUJOCO_KEY=$MUJOCO_KEY

ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/root/.mujoco/mjpro150/bin
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/root/.mujoco/mujoco200/bin
RUN echo $MUJOCO_KEY | base64 --decode > /root/.mujoco/mjkey.txt
RUN [ "$PYTHON_VER" != "2.7" ] && pip install box2d-py atari-py mujoco-py || echo "skipping atari-py, mujoco-py and box2d-py"

COPY . /usr/local/gym/
RUN cd /usr/local/gym && \
    pip install /usr/local/gym pytest pytest-forked

WORKDIR /usr/local/gym/
ENTRYPOINT ["/usr/local/gym/bin/docker_entrypoint"]
CMD ["pytest","--forked"]
