FROM continuumio/anaconda3

RUN apt-get update && apt-get upgrade -y \
 && apt-get install -y \
  libpq-dev \
  build-essential \
  git \
  sudo \
 && rm -rf /var/lib/apt/lists/*

RUN conda install -y -c conda-forge \
  tensorflow=1.0.0 \
  jupyter_contrib_nbextensions

ARG username
ARG userid

RUN adduser ${username} --uid ${userid} --gecos '' --disabled-password \
 && echo "${username} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${username} \
 && chmod 0440 /etc/sudoers.d/${username}

ENV HOME /home/${username}

WORKDIR ${HOME}/handson-ml
RUN chown ${username}:${username} ${HOME}/handson-ml

USER ${username}

RUN jupyter contrib nbextension install --user
RUN jupyter nbextension enable toc2/main


# INFO: Uncomment the RUN command below for easy and constant notebook URL (just localhost:8888)
#       That will switch jupyter to using empty password instead of a token.
#       To avoid making a security hole you SHOULD in fact not only uncomment but
#       regenerate the hash for your own non-empty password and replace the hash below.
#       You can compute a password hash in any notebook, just run the code:
#          from notebook.auth import passwd
#          passwd()
#       and take the hash from the output
#RUN mkdir -p ${HOME}/.jupyter && \
# echo 'c.NotebookApp.password = u"sha1:c6bbcba2d04b:f969e403db876dcfbe26f47affe41909bd53392e"' \
# >> ${HOME}/.jupyter/jupyter_notebook_config.py

# INFO: Uncomment the RUN command below to disable git diff paging
#RUN git config --global core.pager ''


# INFO: Below - work in progress, nbdime not totally integrated, still it enables diffing
#       notebooks with nbdiff (and nbdiff support in git diff command) after connecting to
#       the container by "make exec" (docker exec)
#  Try:
#      nbd NOTEBOOK_NAME.ipynb
#    to get nbdiff between checkpointed version and current version of the given notebook
USER root
WORKDIR /

RUN conda install -y -c conda-forge nbdime

USER ${username}
WORKDIR ${HOME}/handson-ml

RUN git-nbdiffdriver config --enable --global

# INFO: Uncomment the RUN command below to ignore metadata in nbdiff within git diff
#RUN git config --global diff.jupyternotebook.command 'git-nbdiffdriver diff --ignore-metadata'


COPY docker/bashrc /tmp/bashrc
RUN cat /tmp/bashrc >> ${HOME}/.bashrc
RUN sudo rm -rf /tmp/bashrc
