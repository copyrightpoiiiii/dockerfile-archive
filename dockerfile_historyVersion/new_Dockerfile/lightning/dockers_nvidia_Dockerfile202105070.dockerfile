# Copyright The PyTorch Lightning team.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# https://docs.nvidia.com/deeplearning/frameworks/pytorch-release-notes
FROM nvcr.io/nvidia/pytorch:21.04-py3

MAINTAINER PyTorchLightning <https://github.com/PyTorchLightning>

ARG LIGHTNING_VERSION=""

RUN python -c "import torch ; print(torch.__version__)" >> torch_version.info

COPY ./ /workspace/pytorch-lightning/

RUN \
    cd /workspace  && \
    # replace by specific version if asked
    if [ ! -z "$LIGHTNING_VERSION" ] ; then \
        rm -rf pytorch-lightning ; \
        wget https://github.com/PyTorchLightning/pytorch-lightning/archive/${LIGHTNING_VERSION}.zip --progress=bar:force:noscroll ; \
        unzip ${LIGHTNING_VERSION}.zip ; \
        mv pytorch-lightning-*/ pytorch-lightning ; \
        rm *.zip ; \
    fi && \
# save the examples
    mv pytorch-lightning/notebooks . && \
    mv pytorch-lightning/pl_examples . && \

# Installations
    python -c "fname = './pytorch-lightning/requirements/extra.txt' ; lines = [line for line in open(fname).readlines() if not line.startswith('horovod')] ; open(fname, 'w').writelines(lines)" && \
    pip install -r ./pytorch-lightning/requirements/extra.txt --no-cache-dir --upgrade-strategy only-if-needed && \
    pip install -r ./pytorch-lightning/requirements/examples.txt --no-cache-dir --upgrade-strategy only-if-needed && \
    pip install ./pytorch-lightning --no-cache-dir && \
    pip install "Pillow>=8.1" --no-cache-dir --upgrade-strategy only-if-needed && \
    rm -rf pytorch-lightning && \
    pip list

RUN pip install lightning-grid -U

ENV PYTHONPATH="/workspace"

RUN \
    TORCH_VERSION=$(cat torch_version.info) && \
    rm torch_version.info && \
    python --version && \
    pip --version && \
    pip list | grep torch && \
    python -c "from torch import __version__ as ver ; assert ver == '$TORCH_VERSION', ver" && \
    python -c "import pytorch_lightning as pl; print(pl.__version__)"

CMD ["jupyter", "notebook", "--port=8888", "--no-browser", "--ip=0.0.0.0", "--allow-root"]
