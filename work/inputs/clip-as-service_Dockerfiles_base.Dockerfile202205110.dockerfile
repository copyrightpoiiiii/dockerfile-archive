# !!! An ARG declared before a FROM is outside of a build stage, so it can’t be used in any instruction after a FROM
ARG JINA_VERSION=3.3.25

FROM jinaai/jina:${JINA_VERSION}-py38-standard

ARG PIP_TAG

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
COPY . /clip-as-service/

RUN echo '\
jtype: CLIPEncoder\n\
with:\n\
  name: ${{ env.MODEL_NAME }}\n\
  device: ${{ env.DEVICE }}\n\
  minibatch_size: ${{ env.MINIBATCH_SIZE }}\n\
metas:\n\
  py_modules:\n\
    - server/clip_server/executors/clip_${{ env.ENGINE }}.py\n\
' > /tmp/config.yml

RUN cd /clip-as-service && \
    if [ -n "$PIP_TAG" ]; then pip3 install --no-cache-dir server/"[$PIP_TAG]" ; fi && \
    pip3 install --no-cache-dir "server/"

WORKDIR /clip-as-service


ENTRYPOINT ["jina", "executor", "--uses", "/tmp/config.yml"]
