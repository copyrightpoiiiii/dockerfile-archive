FROM microsoft/dotnet:2.0-runtime

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        openssl \
&& rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY obj/Docker/publish .
