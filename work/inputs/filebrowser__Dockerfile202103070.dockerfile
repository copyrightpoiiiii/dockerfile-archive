FROM alpine:latest
RUN apk --update add ca-certificates
RUN apk --update add mailcap

VOLUME /srv
EXPOSE 80

COPY .docker.json /.filebrowser.json
COPY filebrowser /filebrowser

ENTRYPOINT [ "/filebrowser" ]
