ARG BASE=researchdeezer/spleeter
ARG MODEL=2-stems

FROM ${BASE}

RUN mkdir -p /model/$MODEL \
    && wget -O /tmp/$MODEL.tar.gz https://github.com/deezer/spleeter/releases/download/v1.4.0/$MODEL.tar.gz \
    && tar -xvzf /tmp/$MODEL.tar.gz -C /model/$MODEL/ \
    && touch /model/$MODEL/.probe
