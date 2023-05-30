FROM gitpod/workspace-full
USER gitpod

ENV PATH="$HOME/.pulumi:$HOME/.pulumi/bin:$PATH"

# Install .NET Core 3.1 SDK binaries on Ubuntu 20.04
# Source: https://dev.to/carlos487/installing-dotnet-core-in-ubuntu-20-04-6jh
RUN mkdir -p /home/gitpod/dotnet && \
     curl -fsSL https://download.visualstudio.microsoft.com/download/pr/f65a8eb0-4537-4e69-8ff3-1a80a80d9341/cc0ca9ff8b9634f3d9780ec5915c1c66/dotnet-sdk-3.1.201-linux-x64.tar.gz \
     | tar xz -C /home/gitpod/dotnet && \
     wget -qO- https://github.com/pulumi/pulumictl/releases/download/v0.0.28/pulumictl-v0.0.28-linux-amd64.tar.gz | sudo tar zxvf - -C /usr/local/bin


ENV DOTNET_ROOT=/home/gitpod/dotnet
ENV PATH=$PATH:/home/gitpod/dotnet:/usr/local/bin
