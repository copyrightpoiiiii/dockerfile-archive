FROM mcr.microsoft.com/dotnet/core/aspnet:2.2 AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/core/sdk:2.2 AS build
WORKDIR /src

COPY Dockerfile-scripts Dockerfile-scripts/

COPY src/ApiGateways/*/*.csproj /src/csproj-files/
COPY src/ApiGateways/*/*/*.csproj /src/csproj-files/
COPY src/BuildingBlocks/*/*/*.csproj /src/csproj-files/
COPY src/Services/*/*/*.csproj /src/csproj-files/
COPY src/Web/*/*.csproj /src/csproj-files/

RUN Dockerfile-scripts/restore-packages

COPY . .
WORKDIR /src/src/Services/Catalog/Catalog.API
RUN dotnet publish -c Release -o /app

FROM build as unittest
WORKDIR /src/src/Services/Catalog/Catalog.UnitTests

FROM build as functionaltest
WORKDIR /src/src/Services/Catalog/Catalog.FunctionalTests

FROM build AS publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app .
ENTRYPOINT ["dotnet", "Catalog.API.dll"]
