FROM microsoft/dotnet:2.1.4-aspnetcore-runtime

LABEL com.bitwarden.product="bitwarden"

COPY obj/Docker/publish /bitwarden_server
