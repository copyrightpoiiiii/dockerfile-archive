FROM centos:centos6

# just a comment

RUN yum clean all && \
    yum -y install epel-release && \
    yum -y install \
    acl \
    asciidoc \
    bzip2 \
    file \
    gcc \
    git \
    make \
    mercurial \
    mysql \
    MySQL-python \
    mysql-server \
    openssh-clients \
    openssh-server \
    python-coverage \
    python-devel \
    python-httplib2 \
    python-keyczar \
    python-mock \
    python-nose \
    python-paramiko \
    python-passlib \
    python-pip \
    python-setuptools \
    python-virtualenv \
    PyYAML \
    rpm-build \
    rubygems \
    sed \
    subversion \
    sudo \
    unzip \
    which \
    zip \
    && \
    yum clean all

RUN rpm -e --nodeps python-crypto && pip install --upgrade jinja2 pycrypto

RUN /bin/sed -i -e 's/^\(Defaults\s*requiretty\)/#--- \1/'  /etc/sudoers
RUN mkdir /etc/ansible/
RUN /bin/echo -e '[local]\nlocalhost ansible_connection=local' > /etc/ansible/hosts
VOLUME /sys/fs/cgroup /run /tmp
RUN ssh-keygen -q -t rsa1 -N '' -f /etc/ssh/ssh_host_key && \
    ssh-keygen -q -t dsa -N '' -f /etc/ssh/ssh_host_dsa_key && \
    ssh-keygen -q -t rsa -N '' -f /etc/ssh/ssh_host_rsa_key && \
    ssh-keygen -q -t rsa -N '' -f /root/.ssh/id_rsa && \
    cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys && \
    for key in /etc/ssh/ssh_host_*_key.pub; do echo "localhost $(cat ${key})" >> /root/.ssh/known_hosts; done
RUN pip install junit-xml
ENV container=docker
CMD ["/sbin/init"]
