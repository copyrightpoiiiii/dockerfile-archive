FROM golang:1.12

RUN go get -u github.com/pion/webrtc/v2/examples/pion-to-pion/offer

CMD ["offer"]
