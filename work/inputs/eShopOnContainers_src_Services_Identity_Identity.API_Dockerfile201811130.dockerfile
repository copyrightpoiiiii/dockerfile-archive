FROM microsoft/dotnet:2.2.0-preview3-aspnetcore-runtime AS base
WORKDIR /app
EXPOSE 80

FROM microsoft/dotnet:2.2.100-preview3-sdk AS dotnet-build
WORKDIR /src

FROM dotnet-build as build
WORKDIR /src
COPY . .
WORKDIR /src/src/Services/Identity/Identity.API
RUN dotnet restore -nowarn:msb3202,nu1503
RUN dotnet build --no-restore -c Release -o /app

FROM build AS publish
RUN dotnet publish --no-restore -c Release -o /app

FROM base AS final
WORKDIR /app
COPY --from=publish /app .
ENTRYPOINT ["dotnet", "Identity.API.dll"]
