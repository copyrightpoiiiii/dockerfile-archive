# We build our DevContainer on MS' Typescript-Node Devcontainer
# This gives us lots of standard stuff, and lets us layer a few custom things on top, like the Emscripten compiler, Puppeteer

# --------------------------------------------------------------------
# BEGIN Standard MS Devcontainer for Typescript-Node 

# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.155.1/containers/typescript-node/.devcontainer/base.Dockerfile
# [Choice] Node.js version: 14, 12, 10
ARG VARIANT="14-buster"
FROM mcr.microsoft.com/vscode/devcontainers/typescript-node:0-${VARIANT}

# [Optional] Uncomment if you want to install an additional version of node using nvm
# ARG EXTRA_NODE_VERSION=10
# RUN su node -c "source /usr/local/share/nvm/nvm.sh && nvm install ${EXTRA_NODE_VERSION}"

# [Optional] Uncomment if you want to install more global node packages
# RUN su node -c "npm install -g <your-package-list -here>"

# END Standard MS Devcontainer for Typescript-Node 
# --------------------------------------------------------------------

# --------------------------------------------------------------------
# BEGIN EMSDK 
# Install EMSDK to /emsdk just like the EMSDK Dockerfile: https://github.com/emscripten-core/emsdk/blob/master/docker/Dockerfile
ENV EMSDK /emsdk
# We pin the EMSDK version rather than 'latest' so that everyone is using the same compiler version
ENV EMSCRIPTEN_VERSION 3.0.0

RUN git clone https://github.com/emscripten-core/emsdk.git $EMSDK

RUN echo "## Install Emscripten" \
    && cd ${EMSDK} \
    && ./emsdk install ${EMSCRIPTEN_VERSION} \
    && echo "## Done"

# Copied directly from https://github.com/emscripten-core/emsdk/blob/master/docker/Dockerfile
RUN cd ${EMSDK} \
    && echo "## Generate standard configuration" \
    && ./emsdk activate ${EMSCRIPTEN_VERSION} \
    && chmod 777 ${EMSDK}/upstream/emscripten \
    && chmod -R 777 ${EMSDK}/upstream/emscripten/cache \
    && echo "int main() { return 0; }" > hello.c \
    && ${EMSDK}/upstream/emscripten/emcc -c hello.c \
    && cat ${EMSDK}/upstream/emscripten/cache/sanity.txt \
    && echo "## Done"

ENV PATH $EMSDK:$EMSDK/upstream/emscripten/:$PATH

# Cleanup Emscripten installation and strip some symbols
# Copied directly from https://github.com/emscripten-core/emsdk/blob/master/docker/Dockerfile
RUN echo "## Aggressive optimization: Remove debug symbols" \
    && cd ${EMSDK} && . ./emsdk_env.sh \
    # Remove debugging symbols from embedded node (extra 7MB)
    && strip -s `which node` \
    # Tests consume ~80MB disc space
    && rm -fr ${EMSDK}/upstream/emscripten/tests \
    # Fastcomp is not supported
    && rm -fr ${EMSDK}/upstream/fastcomp \
    # strip out symbols from clang (~extra 50MB disc space)
    && find ${EMSDK}/upstream/bin -type f -exec strip -s {} + || true \
    && echo "## Done"

RUN echo ". /emsdk/emsdk_env.sh" >> /etc/bash.bashrc
# We must set the EM_NODE_JS environment variable for a somewhat silly reason
# We run our build scripts with `npm run`, which sets the NODE environment variable as it runs.
# The EMSDK picks up on that environment variable and gives a deprecation warning: warning: honoring legacy environment variable `NODE`.  Please switch to using `EM_NODE_JS` instead`
# So, we are going to put this environment variable here explicitly to avoid the deprecation warning.
RUN echo 'export EM_NODE_JS="$EMSDK_NODE"' >> /etc/bash.bashrc

# END EMSDK
# --------------------------------------------------------------------

# --------------------------------------------------------------------
# BEGIN PUPPETEER dependencies
# Here we install all of the packages depended upon by Chrome (that Puppeteer will use for headless tests).
# We could also take a page from https://github.com/buildkite/docker-puppeteer/blob/master/Dockerfile instead,
# and install the latest stable version of Chrome to get the right dependencies, but that version changes over time,
# so the stable version of Chrome and the version installed by Puppeteer might diverge over time. 
# It also means they end up having Chrome downloaded and installed twice.
# We could install the particular version of Chrome that our version of Puppeteer would use and then tell Puppeteer not to download its own version of Chrome,
# but then we'd have to rebuild our Docker container every time we revved Puppeteer, and that feels fiddly too.
# For all of these reasons, it seems safer to simply install the explicit list packages depended upon by Chrome, assume that's unlikely to change
# and move on.

# List taken from:
# https://github.com/puppeteer/puppeteer/blob/main/docs/troubleshooting.md#chrome-headless-doesnt-launch-on-unix
RUN apt-get update \
     && apt-get install -y \
        ca-certificates \
        fonts-liberation \
        libappindicator3-1 \
        libasound2 \
        libatk-bridge2.0-0 \
        libatk1.0-0 \
        libc6 \
        libcairo2 \
        libcups2 \
        libdbus-1-3 \
        libexpat1 \
        libfontconfig1 \
        libgbm1 \
        libgcc1 \
        libglib2.0-0 \
        libgtk-3-0 \
        libnspr4 \
        libnss3 \
        libpango-1.0-0 \
        libpangocairo-1.0-0 \
        libstdc++6 \
        libx11-6 \
        libx11-xcb1 \
        libxcb1 \
        libxcomposite1 \
        libxcursor1 \
        libxdamage1 \
        libxext6 \
        libxfixes3 \
        libxi6 \
        libxrandr2 \
        libxrender1 \
        libxss1 \
        libxtst6 \
        lsb-release \
        wget \
        xdg-utils

# Installs the command "sha3sum", which is used check the download integrity of sqlite source.
RUN apt-get install -y libdigest-sha3-perl

# We set this env variable (RUN_WORKER_TEST_WITHOUT_PUPPETEER_SANDBOX=1) this to tell our sql.js test harness to run Puppeteer without the sandbox.
# Otherwise, when we instantiate Puppeteer, we get this error: 
# Puppeteer can't start due to a sandbox error. (Details follow.)
#     [0321/173044.694524:FATAL:zygote_host_impl_linux.cc(117)] No usable sandbox! Update your kernel or see https://chromium.googlesource.com/chromium/src/+/master/docs/linux/suid_sandbox_development.md for more information on developing with the SUID sandbox. If you want to live dangerously and need an immediate workaround, you can try using --no-sandbox.
ENV RUN_WORKER_TEST_WITHOUT_PUPPETEER_SANDBOX=1

# END PUPPETEER
# --------------------------------------------------------------------
