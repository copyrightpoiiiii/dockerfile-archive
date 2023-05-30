FROM python:2.7

WORKDIR /usr/app/

COPY ./requirements/prod.txt .
RUN pip install futures

RUN pip install -r prod.txt -i https://mirrors.aliyun.com/pypi/simple

COPY . .

CMD python waller.py
