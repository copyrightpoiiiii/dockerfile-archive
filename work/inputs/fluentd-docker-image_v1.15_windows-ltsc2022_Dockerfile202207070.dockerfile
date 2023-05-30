# AUTOMATICALLY GENERATED
# DO NOT EDIT THIS FILE DIRECTLY, USE /Dockerfile.template.erb

FROM mcr.microsoft.com/windows/servercore:ltsc2022
LABEL maintainer "Fluentd developers <fluentd@googlegroups.com>"
LABEL Description="Fluentd docker image" Vendor="Fluent Organization" Version="1.15.0"

# Do not split this into multiple RUN!
# Docker creates a layer for every RUN-Statement
RUN powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))"

# NOTE: For avoiding stalling with docker build on windows, we must use latest version of msys2.
RUN choco install -y ruby --version 3.1.2.1 --params "'/InstallDir:C:\ruby31'" \
&& choco install -y msys2 --version 20220319.0.0 --params "'/NoPath /NoUpdate /InstallDir:C:\ruby31\msys64'"
RUN refreshenv \
&& ridk install 3 \
&& echo gem: --no-document >> C:\ProgramData\gemrc \
&& gem install oj -v 3.13.5 \
&& gem install json -v 2.6.2 \
&& gem install fluentd -v 1.15.0 \
&& gem install win32-service -v 2.3.2 \
&& gem install win32-ipc -v 0.7.0 \
&& gem install win32-event -v 0.6.3 \
&& gem install windows-pr -v 1.2.6 \
&& gem sources --clear-all

# Remove gem cache and chocolatey
RUN powershell -Command "Remove-Item -Force C:\ruby31\lib\ruby\gems\3.1.0\cache\*.gem; Remove-Item -Recurse -Force 'C:\ProgramData\chocolatey'"

COPY fluent.conf /fluent/conf/fluent.conf


ENV FLUENTD_CONF="fluent.conf"

EXPOSE 24224 5140

ENTRYPOINT ["cmd", "/k", "fluentd", "--config", "C:\\fluent\\conf\\fluent.conf"]
