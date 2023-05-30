# !!! An ARG declared before a FROM is outside of a build stage, so it can’t be used in any instruction after a FROM
ARG JINA_VERSION=3.6.0

FROM jinaai/jina:${JINA_VERSION}-py38-standard

ARG BACKEND_TAG=torch

# constant, wont invalidate cache
LABEL org.opencontainers.image.vendor="Jina AI Limited" \
      org.opencontainers.image.licenses="Apache 2.0" \
      org.opencontainers.image.title="Clip-As-Service" \
      org.opencontainers.image.description="Embed images and sentences into fixed-length vectors with CLIP" \
      org.opencontainers.image.authors="hello@jina.ai" \
      org.opencontainers.image.url="clip-as-service" \
      org.opencontainers.image.documentation="https://clip-as-service.jina.ai/"

RUN pip3 install --no-cache-dir torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cpu

# copy will almost always invalid the cache
COPY . /clip_server/

RUN echo "\
jtype: CLIPEncoder\n\
metas:\n\
  py_modules:\n\
    - clip_server/executors/clip_$BACKEND_TAG.py\n\
" > /tmp/config.yml

RUN cd /clip_server && \
    if [ "$BACKEND_TAG" != "torch" ]; then pip3 install --no-cache-dir "./[$BACKEND_TAG]" ; fi && \
    pip3 install --no-cache-dir .

WORKDIR /clip_server


ENTRYPOINT ["jina", "executor", "--uses", "/tmp/config.yml"]
