#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM mcr.microsoft.com/windows/nanoserver:ltsc2022

SHELL ["cmd", "/S", "/C"]

# PATH isn't actually set in the Docker image, so we have to set it from within the container
USER ContainerAdministrator
RUN setx /m PATH "C:\mongodb\bin;%PATH%"
USER ContainerUser
# doing this first to share cache across versions more aggressively

COPY --from=mongo:4.2.20-windowsservercore-ltsc2022 \
 C:\\Windows\\System32\\msvcp140.dll \
 C:\\Windows\\System32\\vcruntime140.dll \
 C:\\Windows\\System32\\

# https://docs.mongodb.org/master/release-notes/4.2/
ENV MONGO_VERSION 4.2.20
# 05/04/2022, https://github.com/mongodb/mongo/tree/15c0712952c356cb711c13a42cb3bca8617d4ebc

COPY --from=mongo:4.2.20-windowsservercore-ltsc2022 C:\\mongodb C:\\mongodb
RUN mongo --version && mongod --version

VOLUME C:\\data\\db C:\\data\\configdb

EXPOSE 27017
CMD ["mongod", "--bind_ip_all"]
