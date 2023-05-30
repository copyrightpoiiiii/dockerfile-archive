FROM zaqwsx_ipfs-test-img

RUN ipfs init -b=1024
ADD . /tmp/test
RUN mv -f /tmp/test/config /root/.go-ipfs/config
RUN ipfs id
RUN chmod +x /tmp/test/run.sh

EXPOSE 4021 4022/udp

ENV IPFS_LOGGING_FMT nocolor

ENTRYPOINT ["/bin/bash"]
CMD ["/tmp/test/run.sh"]