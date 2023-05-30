FROM mcr.microsoft.com/windows/servercore:1809

# $ProgressPreference: https://github.com/PowerShell/PowerShell/issues/2138#issuecomment-251261324
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ENV JULIA_VERSION 1.6.4
ENV JULIA_SHA256 c9b6ecdad4feb57e5af12c9ef1a74993a96edbf87a4dc521d57e338397cee9b2

RUN $url = ('https://julialang-s3.julialang.org/bin/winnt/x64/{1}/julia-{0}-win64.exe' -f $env:JULIA_VERSION, ($env:JULIA_VERSION.Split('.')[0..1] -Join '.')); \
 Write-Host ('Downloading {0} ...' -f $url); \
 [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; \
 Invoke-WebRequest -Uri $url -OutFile 'julia.exe'; \
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
 Write-Host 'Updating PATH ...'; \
 $env:PATH = 'C:\julia\bin;' + $env:PATH; \
 [Environment]::SetEnvironmentVariable('PATH', $env:PATH, [EnvironmentVariableTarget]::Machine); \
 \
 Write-Host 'Verifying install ("julia --version") ...'; \
 julia --version; \
 \
 Write-Host 'Removing ...'; \
 Remove-Item julia.exe -Force; \
 \
 Write-Host 'Complete.'

CMD ["julia"]
