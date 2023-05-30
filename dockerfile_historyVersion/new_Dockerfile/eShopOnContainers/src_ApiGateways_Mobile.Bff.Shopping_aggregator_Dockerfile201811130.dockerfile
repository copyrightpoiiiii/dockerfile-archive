FROM microsoft/dotnet:2.2.0-preview3-aspnetcore-runtime AS base
WORKDIR /app
EXPOSE 80

FROM microsoft/dotnet:2.2.100-preview3-sdk AS build
WORKDIR /src
COPY . .
WORKDIR /src/src/ApiGateways/Mobile.Bff.Shopping/aggregator
RUN dotnet restore -nowarn:msb3202,nu1503
RUN dotnet build --no-restore -c Release -o /app

FROM build AS publish
RUN dotnet publish --no-restore -c Release -o /app

FROM base AS final
WORKDIR /app
COPY --from=publish /app .
ENTRYPOINT ["dotnet", "Mobile.Shopping.HttpAggregator.dll"]