FROM kaixhin/cuda-torch

RUN apt-get update && apt-get install -y --no-install-recommends --force-yes \
  libsnappy-dev \
  graphicsmagick \
  libgraphicsmagick1-dev \
  libssl-dev \
  ca-certificates \
  git && \
  rm -rf /var/lib/apt/lists/*

# https://github.com/nagadomi/waifu2x
RUN \
  luarocks install graphicsmagick && \
  luarocks install lua-csnappy && \
  luarocks install md5 && \
  luarocks install uuid && \
  luarocks install csvigo && \
  PREFIX=$HOME/torch/install luarocks install turbo && \
  luarocks install cudnn

COPY . /root/waifu2x

WORKDIR /root/waifu2x