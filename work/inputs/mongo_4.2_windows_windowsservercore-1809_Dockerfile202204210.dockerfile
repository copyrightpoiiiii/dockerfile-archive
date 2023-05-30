#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM mcr.microsoft.com/windows/servercore:1809

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';"]

# https://docs.mongodb.org/master/release-notes/4.2/
ENV MONGO_VERSION 4.2.19
# 03/02/2022, https://github.com/mongodb/mongo/tree/e68a7d47305e14e090cba9ce3d92533053299996

ENV MONGO_DOWNLOAD_URL https://fastdl.mongodb.org/win32/mongodb-win32-x86_64-2012plus-4.2.19-signed.msi
ENV MONGO_DOWNLOAD_SHA256=6470b3208da1f913014af94b07e1e28bb831a36fb3c130acc9d4949dde6fa7a8

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
   'ADDLOCAL=Client,ImportExportTools,MiscellaneousTools,MonitoringTools,Router,ServerNoService' \
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
