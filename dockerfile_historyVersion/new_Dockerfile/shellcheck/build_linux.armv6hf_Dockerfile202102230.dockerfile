# I've again spent days trying to get a working armv6hf compiler going.
# God only knows how many recompilations of GCC, GHC, libraries, and
# ShellCheck itself, has gone into it.
#
# I tried Debian's toolchain.  I tried my custom one built according to
# RPi `gcc -v`. I tried GHC9, glibc, musl, registerised vs not, but
# nothing has yielded an armv6hf binary that does not immediately
# segfault on qemu-arm-static or the RPi itself.
#
# I then tried the same but with armv7hf. Same story.
#
# Emulating the entire userspace with balenalib again?  Very strange build
# failures where programs would fail to execute with > ~100 arguments.
#
# Finally, creating our own appears to work when using a custom QEmu
# patched to follow execve calls.
#
# PS: $100 bounty for getting a RPi1 compatible static build going
#     with cross-compilation, similar to what the aarch64 build does.
#

FROM ubuntu:20.04

ENV TARGETNAME linux.armv6hf

# Build QEmu with execve follow support
USER root
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update
RUN apt-get install -y build-essential git ninja-build python3 pkg-config libglib2.0-dev libpixman-1-dev
WORKDIR /build
RUN git clone --depth 1 https://github.com/koalaman/qemu
RUN cd qemu && ./configure --static && cd build && ninja qemu-arm
RUN cp qemu/build/qemu-arm /build/qemu-arm-static
ENV QEMU_EXECVE 1

# Set up an armv6 userspace
WORKDIR /
RUN apt-get install -y debootstrap qemu-user-static
# We expect this to fail if the host doesn't have binfmt qemu support
RUN qemu-debootstrap --arch armhf bullseye pi http://mirrordirector.raspbian.org/raspbian || [ -e /pi/etc/issue ]
RUN cp /build/qemu-arm-static /pi/usr/bin/qemu-arm-static
RUN printf > /bin/pirun '%s\n' '#!/bin/sh' 'chroot /pi /usr/bin/qemu-arm-static /usr/bin/env "$@"' && chmod +x /bin/pirun
# If the debootstrap process didn't finish, continue it
RUN [ ! -e /pi/debootstrap ] || pirun '/debootstrap/debootstrap' --second-stage

# Install deps in the chroot
RUN pirun apt-get update
RUN pirun apt-get install -y ghc cabal-install

# Finally we can build the current dependencies. This takes hours.
ENV CABALOPTS "--ghc-options;-split-sections -optc-Os -optc-Wl,--gc-sections;--gcc-options;-Os -Wl,--gc-sections -ffunction-sections -fdata-sections"
RUN pirun cabal update
RUN IFS=";" && pirun cabal install --lib $CABALOPTS Diff-0.4.0 base-compat-0.11.2 base-orphans-0.8.4 dlist-1.0 hashable-1.3.1.0 indexed-traversable-0.1.1 integer-logarithms-1.0.3.1 primitive-0.7.1.0 regex-base-0.94.0.1 splitmix-0.1.0.3 tagged-0.8.6.1 th-abstraction-0.4.2.0 transformers-compat-0.6.6 base-compat-batteries-0.11.2 time-compat-1.9.5 unordered-containers-0.2.13.0 data-fix-0.3.1 vector-0.12.2.0 scientific-0.3.6.2 regex-tdfa-1.3.1.0 random-1.2.0 distributive-0.6.2.1 attoparsec-0.13.2.5 uuid-types-1.0.4 comonad-5.0.8 bifunctors-5.5.10 assoc-1.0.2 these-1.1.1.1 strict-0.4.0.1 aeson-1.5.6.0

# Copy the build script
WORKDIR /pi/scratch
COPY build /pi/usr/bin
ENTRYPOINT ["/bin/pirun", "/usr/bin/build"]
