#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM mcr.microsoft.com/windows/servercore:ltsc2022

# $ProgressPreference: https://github.com/PowerShell/PowerShell/issues/2138#issuecomment-251261324
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ENV JULIA_VERSION 1.8.0
ENV JULIA_URL https://julialang-s3.julialang.org/bin/winnt/x64/1.8/julia-1.8.0-win64.exe
ENV JULIA_SHA256 a1699278e4884578c10580cf19f8d42401abce78f459c416998221902ea26d38

RUN Write-Host ('Downloading {0} ...' -f $env:JULIA_URL); \
 [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; \
 Invoke-WebRequest -Uri $env:JULIA_URL -OutFile 'julia.exe'; \
 \
 Write-Host ('Verifying sha256 ({0}) ...' -f $env:JULIA_SHA256); \
 if ((Get-FileHash julia.exe -Algorithm sha256).Hash -ne $env:JULIA_SHA256) { \
  Write-Host 'FAILED!'; \
  exit 1; \
 }; \
 \
 Write-Host 'Installing ...'; \
 Start-Process -Wait -NoNewWindow \
  -FilePath '.\julia.exe' \
  -ArgumentList @( \
   '/SILENT', \
   '/DIR=C:\julia' \
  ); \
 \
 Write-Host 'Removing ...'; \
 Remove-Item julia.exe -Force; \
 \
 Write-Host 'Updating PATH ...'; \
 $env:PATH = 'C:\julia\bin;' + $env:PATH; \
 [Environment]::SetEnvironmentVariable('PATH', $env:PATH, [EnvironmentVariableTarget]::Machine); \
 \
 Write-Host 'Verifying install ("julia --version") ...'; \
 julia --version; \
 \
 Write-Host 'Complete.'

CMD ["julia"]
