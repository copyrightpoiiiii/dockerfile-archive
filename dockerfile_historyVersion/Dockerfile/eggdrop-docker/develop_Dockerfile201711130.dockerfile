FROM alpine:3.5
MAINTAINER Geo Van O <geo@eggheads.org>

RUN adduser -S eggdrop

# grab su-exec for easy step-down from root
RUN apk add --no-cache 'su-exec>=0.2'

ENV EGGDROP_SHA256 880aef0a11442a8f972f7267079abcceff4ce37a0ce3054141359470c0585228
ENV EGGDROP_COMMIT 5d9da79dd6b8b9a8f392701dbdd343e8dae73644

RUN apk --update add --no-cache tcl bash openssl
RUN apk --update add --no-cache --virtual egg-deps tcl-dev wget ca-certificates make tar gpgme build-base openssl-dev \
  && wget "https://github.com/eggheads/eggdrop/archive/$EGGDROP_COMMIT.tar.gz" -O develop.tar.gz \
  && echo "$EGGDROP_SHA256  develop.tar.gz" | sha256sum -c - \
  && tar -zxvf develop.tar.gz \
  && rm develop.tar.gz \
    && ( cd eggdrop-$EGGDROP_COMMIT \
    && ./configure \
    && make config \
    && make \
    && make install DEST=/home/eggdrop/eggdrop ) \
  && rm -rf eggdrop-$EGGDROP_COMMIT \
  && mkdir /home/eggdrop/eggdrop/data \
  && chown -R eggdrop /home/eggdrop/eggdrop \
  && apk del egg-deps

ENV NICK=""
ENV SERVER=""
ENV LISTEN="3333"
ENV OWNER=""
ENV USERFILE="eggdrop.user"
ENV CHANFILE="eggdrop.chan"

WORKDIR /home/eggdrop/eggdrop
EXPOSE 3333
COPY entrypoint.sh /home/eggdrop/eggdrop
COPY docker.tcl /home/eggdrop/eggdrop/scripts/

ENTRYPOINT ["/home/eggdrop/eggdrop/entrypoint.sh"]
CMD ["eggdrop.conf"]
