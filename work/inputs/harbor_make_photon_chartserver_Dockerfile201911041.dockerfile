FROM photon:2.0

RUN tdnf install -y shadow sudo >>/dev/null\
    && tdnf clean all \
    && groupadd -r -g 10000 chart \
    && useradd --no-log-init -m -g 10000 -u 10000 chart

COPY ./make/photon/chartserver/binary/chartm /home/chart/
COPY ./make/photon/chartserver/docker-entrypoint.sh /home/chart/
COPY ./make/photon/common/install_cert.sh /home/chart/

RUN chmod -R 777 /etc/pki/tls/certs \
    && chown -R chart:chart /home/chart \
    && chmod u+x /home/chart/chartm \
    && chmod u+x /home/chart/docker-entrypoint.sh \
    && chmod u+x /home/chart/install_cert.sh

USER chart

WORKDIR /home/chart

ENTRYPOINT ["./docker-entrypoint.sh"]

VOLUME ["/chart_storage"]
EXPOSE 9999

HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD curl -sS 127.0.0.1:9999/health || exit 1
