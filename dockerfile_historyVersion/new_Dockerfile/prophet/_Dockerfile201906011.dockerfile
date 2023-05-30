FROM python:3.7-stretch

RUN apt-get -y install libc-dev

RUN pip install pip==19.1.1

COPY python/requirements.txt .
RUN pip install -r requirements.txt

COPY . .

WORKDIR python

RUN python setup.py install

WORKDIR /
