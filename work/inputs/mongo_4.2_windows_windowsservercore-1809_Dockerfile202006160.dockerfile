FROM mcr.microsoft.com/windows/servercore:1809

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';"]

ENV MONGO_VERSION 4.2.8
ENV MONGO_DOWNLOAD_URL https://fastdl.mongodb.org/win32/mongodb-win32-x86_64-2012plus-4.2.8-signed.msi
ENV MONGO_DOWNLOAD_SHA256=166c5cd99132d72969a67446e494da6287710a34f3f75ee9fb798a2945c0f502

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
   'INSTALLLOCATION=C:\mongodb', \
   'ADDLOCAL=all' \
  ); \
 $env:PATH = 'C:\mongodb\bin;' + $env:PATH; \
 [Environment]::SetEnvironmentVariable('PATH', $env:PATH, [EnvironmentVariableTarget]::Machine); \
 \
 Write-Host 'Verifying install ...'; \
 Write-Host '  mongo --version'; mongo --version; \
 Write-Host '  mongod --version'; mongod --version; \
 \
 Write-Host 'Removing ...'; \
 Remove-Item C:\mongodb\bin\*.pdb -Force; \
 Remove-Item C:\windows\installer\*.msi -Force; \
 Remove-Item mongo.msi -Force; \
 \
 Write-Host 'Complete.';

VOLUME C:\\data\\db C:\\data\\configdb

# TODO docker-entrypoint.ps1 ? (for "docker run <image> --flag --flag --flag")

EXPOSE 27017
CMD ["mongod", "--bind_ip_all"]
