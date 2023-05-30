FROM python:2.7

RUN mkdir /opt/walle-web && mkdir -p /data/walle

ADD ./requirements/prod.txt /usr/app/

RUN pip install -r /usr/app/prod.txt -i https://mirrors.aliyun.com/pypi/simple

EXPOSE 5000

CMD ["/bin/bash"]
