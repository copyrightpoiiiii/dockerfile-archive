#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM mcr.microsoft.com/windows/nanoserver:1809

SHELL ["cmd", "/S", "/C"]

# PATH isn't actually set in the Docker image, so we have to set it from within the container
USER ContainerAdministrator
RUN setx /m PATH "C:\mongodb\bin;%PATH%"
USER ContainerUser
# doing this first to share cache across versions more aggressively

COPY --from=mongo:5.0.13-windowsservercore-1809 \
 C:\\Windows\\System32\\msvcp140.dll \
 C:\\Windows\\System32\\vcruntime140.dll \
 C:\\Windows\\System32\\vcruntime140_1.dll \
 C:\\Windows\\System32\\

# https://docs.mongodb.org/master/release-notes/5.0/
ENV MONGO_VERSION 5.0.13
# 09/29/2022, https://github.com/mongodb/mongo/tree/cfb7690563a3144d3d1175b3a20c2ec81b662a8f

COPY --from=mongo:5.0.13-windowsservercore-1809 C:\\mongodb C:\\mongodb
RUN mongo --version && mongod --version

VOLUME C:\\data\\db C:\\data\\configdb

EXPOSE 27017
CMD ["mongod", "--bind_ip_all"]
