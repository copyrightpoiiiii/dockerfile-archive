FROM microsoft/dotnet:2.1-aspnetcore-runtime AS base
WORKDIR /app
EXPOSE 80

FROM microsoft/dotnet:2.1-sdk AS build
WORKDIR /src
COPY . .
WORKDIR /src/src/Services/Catalog/Catalog.API
RUN dotnet restore -nowarn:msb3202,nu1503
RUN dotnet build --no-restore -c Release -o /app

FROM build as functionaltest
WORKDIR /src/src/Services/Catalog/Catalog.FunctionalTests

FROM build as test
WORKDIR /src/src/Services/Catalog/Catalog.UnitTests
RUN dotnet test --logger trx;LogFileName=/catalog.api.unit-test-results.xml

FROM build AS publish
RUN dotnet publish --no-restore -c Release -o /app

FROM base AS final
WORKDIR /app
COPY --from=publish /app .
ENTRYPOINT ["dotnet", "Catalog.API.dll"]
