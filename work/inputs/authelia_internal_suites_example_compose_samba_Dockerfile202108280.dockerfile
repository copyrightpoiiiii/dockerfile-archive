FROM alpine:3.14.2

RUN \
apk add --no-cache \
  bash \
  krb5 \
  openldap-clients \
  samba-dc \
  supervisor

ADD init.sh /init.sh
CMD /init.sh setup
