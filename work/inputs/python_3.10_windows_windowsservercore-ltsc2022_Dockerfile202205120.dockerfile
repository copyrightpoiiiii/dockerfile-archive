#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM mcr.microsoft.com/windows/servercore:ltsc2022

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# https://github.com/docker-library/python/pull/557
ENV PYTHONIOENCODING UTF-8

ENV PYTHON_VERSION 3.10.4

RUN $url = ('https://www.python.org/ftp/python/{0}/python-{1}-amd64.exe' -f ($env:PYTHON_VERSION -replace '[a-z]+[0-9]*$', ''), $env:PYTHON_VERSION); \
 Write-Host ('Downloading {0} ...' -f $url); \
 [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; \
 Invoke-WebRequest -Uri $url -OutFile 'python.exe'; \
 \
 Write-Host 'Installing ...'; \
# https://docs.python.org/3/using/windows.html#installing-without-ui
 $exitCode = (Start-Process python.exe -Wait -NoNewWindow -PassThru \
  -ArgumentList @( \
   '/quiet', \
   'InstallAllUsers=1', \
   'TargetDir=C:\Python', \
   'PrependPath=1', \
   'Shortcuts=0', \
   'Include_doc=0', \
   'Include_pip=0', \
   'Include_test=0' \
  ) \
 ).ExitCode; \
 if ($exitCode -ne 0) { \
  Write-Host ('Running python installer failed with exit code: {0}' -f $exitCode); \
  Get-ChildItem $env:TEMP | Sort-Object -Descending -Property LastWriteTime | Select-Object -First 1 | Get-Content; \
  exit $exitCode; \
 } \
 \
# the installer updated PATH, so we should refresh our local value
 $env:PATH = [Environment]::GetEnvironmentVariable('PATH', [EnvironmentVariableTarget]::Machine); \
 \
 Write-Host 'Verifying install ...'; \
 Write-Host '  python --version'; python --version; \
 \
 Write-Host 'Removing ...'; \
 Remove-Item python.exe -Force; \
 Remove-Item $env:TEMP/Python*.log -Force; \
 \
 Write-Host 'Complete.'

# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 22.0.4
# https://github.com/docker-library/python/issues/365
ENV PYTHON_SETUPTOOLS_VERSION 58.1.0
# https://github.com/pypa/get-pip
ENV PYTHON_GET_PIP_URL https://github.com/pypa/get-pip/raw/2d26a16e351a22108b46fa11507aa57a732d4074/public/get-pip.py
ENV PYTHON_GET_PIP_SHA256 530e7077f9e31f0378b5ee7cc90c8d99b7aef832f3d4ea96b42c2072e322734e

RUN Write-Host ('Downloading get-pip.py ({0}) ...' -f $env:PYTHON_GET_PIP_URL); \
 [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; \
 Invoke-WebRequest -Uri $env:PYTHON_GET_PIP_URL -OutFile 'get-pip.py'; \
 Write-Host ('Verifying sha256 ({0}) ...' -f $env:PYTHON_GET_PIP_SHA256); \
 if ((Get-FileHash 'get-pip.py' -Algorithm sha256).Hash -ne $env:PYTHON_GET_PIP_SHA256) { \
  Write-Host 'FAILED!'; \
  exit 1; \
 }; \
 \
 $env:PYTHONDONTWRITEBYTECODE = '1'; \
 \
 Write-Host ('Installing pip=={0} ...' -f $env:PYTHON_PIP_VERSION); \
 python get-pip.py \
  --disable-pip-version-check \
  --no-cache-dir \
  --no-compile \
  ('pip=={0}' -f $env:PYTHON_PIP_VERSION) \
  ('setuptools=={0}' -f $env:PYTHON_SETUPTOOLS_VERSION) \
 ; \
 Remove-Item get-pip.py -Force; \
 \
 Write-Host 'Verifying pip install ...'; \
 pip --version; \
 \
 Write-Host 'Complete.'

CMD ["python"]
