# syntax=docker/dockerfile:1
FROM --platform=linux/arm/v7 debian:trixie

RUN apt-get update && apt-get install -y --no-install-recommends \
    cmake g++ make nasm zip unzip curl git pkg-config ninja-build perl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN git clone --recurse-submodules https://github.com/cartridge-gg/discordgo cg-discordgo

# Required on every ARM platform -- vcpkg refuses to run at all without this,
# both for its own bootstrap and for every subsequent vcpkg invocation that
# downloads host-side build tools (cmake, ninja) during the actual port builds.
ENV VCPKG_FORCE_SYSTEM_BINARIES=1

# Caps cmake's internal build parallelism (used inside the Makefile's own
# `cmake --build` call) without needing to touch the Makefile itself.
# QEMU armv7 emulation is more prone to segfaulting under heavy parallel
# compiles -- see the Troubleshooting note on this in the guide.
ENV CMAKE_BUILD_PARALLEL_LEVEL=2

WORKDIR /build/cg-discordgo/dave/libdave/cpp

# Confirmed via the inspection pass: libdave vendors its own pinned copy
# of vcpkg as a nested git submodule at cpp/vcpkg (not a separate clone --
# that would risk a version mismatch against what CMakeLists.txt expects).
# --recurse-submodules on the outer clone already checked this out; it
# just needs bootstrapping.
RUN cd vcpkg && ./bootstrap-vcpkg.sh -disableMetrics

# The Makefile's default target (`all`) already does exactly what's
# needed with zero flags: DEFAULT_BUILD_TYPE is overridden to Release
# for this target specifically, and SSL defaults to openssl_3, which
# picks vcpkg-alts/openssl_3/vcpkg.json as the manifest and the vendored
# vcpkg toolchain file automatically.
RUN make

CMD ["/bin/bash"]
