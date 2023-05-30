FROM golang:1.16

ENV GO111MODULE=on
RUN go get -u github.com/pion/webrtc/v3/examples/pion-to-pion/answer

CMD ["answer"]

EXPOSE 50000
