#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM mcr.microsoft.com/windows/servercore:1809

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';"]

# https://docs.mongodb.org/master/release-notes/5.0/
ENV MONGO_VERSION 5.0.7
# 04/06/2022, https://github.com/mongodb/mongo/tree/b977129dc70eed766cbee7e412d901ee213acbda

ENV MONGO_DOWNLOAD_URL https://fastdl.mongodb.org/windows/mongodb-windows-x86_64-5.0.7-signed.msi
ENV MONGO_DOWNLOAD_SHA256=3d9eee63d56ff75176cf03308274a29c9e385704e21a26f5864cfe1357ca3cf7

RUN Write-Host ('Downloading {0} ...' -f $env:MONGO_DOWNLOAD_URL); \
 [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; \
 (New-Object System.Net.WebClient).DownloadFile($env:MONGO_DOWNLOAD_URL, 'mongo.msi'); \
 \
 if ($env:MONGO_DOWNLOAD_SHA256) { \
  Write-Host ('Verifying sha256 ({0}) ...' -f $env:MONGO_DOWNLOAD_SHA256); \
  if ((Get-FileHash mongo.msi -Algorithm sha256).Hash -ne $env:MONGO_DOWNLOAD_SHA256) { \
   Write-Host 'FAILED!'; \
   exit 1; \
  }; \
 }; \
 \
 Write-Host 'Installing ...'; \
# https://docs.mongodb.com/manual/tutorial/install-mongodb-on-windows/#install-mongodb-community-edition
 Start-Process msiexec -Wait \
  -ArgumentList @( \
   '/i', \
   'mongo.msi', \
   '/quiet', \
   '/qn', \
   '/l*v', 'install.log', \
# https://docs.mongodb.com/manual/tutorial/install-mongodb-on-windows-unattended/#run-the-windows-installer-from-the-windows-command-interpreter
   'INSTALLLOCATION=C:\mongodb', \
   'ADDLOCAL=Client,MiscellaneousTools,Router,ServerNoService' \
  ); \
 if (-Not (Test-Path C:\mongodb\bin\mongo.exe -PathType Leaf)) { \
  Write-Host 'Installer failed!'; \
  Get-Content install.log; \
  exit 1; \
 }; \
 Remove-Item install.log; \
 \
 $env:PATH = 'C:\mongodb\bin;' + $env:PATH; \
 [Environment]::SetEnvironmentVariable('PATH', $env:PATH, [EnvironmentVariableTarget]::Machine); \
 \
 Write-Host 'Verifying install ...'; \
 Write-Host '  mongo --version'; mongo --version; \
 Write-Host '  mongod --version'; mongod --version; \
 \
 Write-Host 'Removing ...'; \
 Remove-Item C:\windows\installer\*.msi -Force; \
 Remove-Item mongo.msi -Force; \
 \
 Write-Host 'Complete.';

# TODO docker-entrypoint.ps1 ? (for "docker run <image> --flag --flag --flag")

VOLUME C:\\data\\db C:\\data\\configdb

EXPOSE 27017
CMD ["mongod", "--bind_ip_all"]
