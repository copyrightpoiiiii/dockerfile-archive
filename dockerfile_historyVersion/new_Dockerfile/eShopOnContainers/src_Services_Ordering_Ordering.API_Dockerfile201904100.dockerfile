FROM mcr.microsoft.com/dotnet/core/aspnet:2.2 AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/core/sdk:2.2 AS build
WORKDIR /src
COPY **/*.csproj csproj-files/
# WORKDIR /src/Dockerfile-scripts
# RUN restore-packages
# COPY . .
# WORKDIR /src/src/Services/Ordering/Ordering.API
# RUN dotnet restore -nowarn:msb3202,nu1503
# RUN dotnet build --no-restore -c Release -o /app

# FROM build as functionaltest
# WORKDIR /src/src/Services/Ordering/Ordering.FunctionalTests

# FROM build as unittest
# WORKDIR /src/src/Services/Ordering/Ordering.UnitTests

# FROM build AS publish
# RUN dotnet publish --no-restore -c Release -o /app

# FROM base AS final
# WORKDIR /app
# COPY --from=publish /app .
# ENTRYPOINT ["dotnet", "Ordering.API.dll"]
