FROM bash:4.4

ARG NUM
COPY context.txt .
COPY make.sh .
SHELL ["/usr/local/bin/bash", "-c"]
RUN ./make.sh $NUM
RUN ls -al /workdir | wc
