FROM microsoft/dotnet:2.1-aspnetcore-runtime AS base
WORKDIR /app
EXPOSE 80

FROM microsoft/dotnet:2.1-sdk AS build
WORKDIR /src
COPY . .
WORKDIR /src/src/Services/Basket/Basket.API
RUN dotnet restore -nowarn:msb3202,nu1503
RUN dotnet build --no-restore -c Release -o /app

FROM build as functionaltest
WORKDIR /src/src/Services/Basket/Basket.FunctionalTests

FROM build as test
WORKDIR /src/src/Services/Basket/Basket.UnitTests
RUN dotnet test --logger trx;LogFileName=basket.api.unit-test-results.xml

FROM build AS publish
RUN dotnet publish --no-restore -c Release -o /app

FROM base AS final
WORKDIR /app
COPY --from=publish /app .
ENTRYPOINT ["dotnet", "Basket.API.dll"]
