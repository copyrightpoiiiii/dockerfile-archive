# escape=`
# Simple Dockerfile which copies clr and library build artifacts into target dotnet sdk image
ARG SDK_BASE_IMAGE=mcr.microsoft.com/dotnet/nightly/sdk:6.0-nanoserver-1809
FROM $SDK_BASE_IMAGE as target

ARG TESTHOST_LOCATION=".\\artifacts\\bin\\testhost"
ARG TFM=net6.0
ARG OS=windows
ARG ARCH=x64
ARG CONFIGURATION=Release

ARG COREFX_SHARED_FRAMEWORK_NAME=Microsoft.NETCore.App
ARG SOURCE_COREFX_VERSION=6.0.0
ARG TARGET_SHARED_FRAMEWORK="C:\\Program Files\\dotnet\\shared"
ARG TARGET_COREFX_VERSION=$DOTNET_VERSION

COPY `
    $TESTHOST_LOCATION\$TFM-$OS-$CONFIGURATION-$ARCH\shared\$COREFX_SHARED_FRAMEWORK_NAME\$SOURCE_COREFX_VERSION\ `
    $TARGET_SHARED_FRAMEWORK\$COREFX_SHARED_FRAMEWORK_NAME\$TARGET_COREFX_VERSION\
