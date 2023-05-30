FROM node:16-alpine3.15 as js-builder
RUN apk add --virtual .test g++
COPY test.cpp test.cpp
RUN g++ -g test.cpp -o test
RUN echo "123" >> test.cpp

FROM golang:1.19.1-alpine3.15 as go-builder
RUN apk add python
COPY --from=js-builder test.cpp a.cpp
RUN g++ -g a.cpp -o ans

FROM alpine:3.15.6
RUN mkdir /test
COPY --from=js-builder test a
COPY --from=go-builder ans b
RUN mv a b /test