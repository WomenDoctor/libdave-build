# syntax=docker/dockerfile:1
FROM --platform=linux/arm/v7 debian:trixie

RUN apt-get update && apt-get install -y --no-install-recommends \
    cmake g++ nasm zip unzip curl git pkg-config ninja-build ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN git clone --recurse-submodules https://github.com/cartridge-gg/discordgo cg-discordgo

# Required on every ARM platform -- vcpkg refuses to run at all without this,
# both for its own bootstrap and for every subsequent vcpkg invocation that
# downloads host-side build tools (cmake, ninja) during the actual port builds.
ENV VCPKG_FORCE_SYSTEM_BINARIES=1

RUN git clone https://github.com/microsoft/vcpkg /vcpkg \
    && /vcpkg/bootstrap-vcpkg.sh -disableMetrics

WORKDIR /build/cg-discordgo

# The assumed path (dave/libdave/cpp/) turned up nothing on the first
# inspection pass -- cat produced no output for either Makefile or
# vcpkg.json, meaning neither exists there. Find out what's actually
# in this checkout instead of guessing again.
RUN echo "=== dave/ directory tree (3 levels) ===" && find dave -maxdepth 3 2>&1; \
    echo "=== git submodule status ===" && git submodule status 2>&1; \
    echo "=== searching whole repo for Makefile/vcpkg.json ===" && find . -iname "Makefile" -o -iname "vcpkg.json" 2>&1

# --- Full build (commented out for the inspection pass) ---
# Uncomment once Phase 3's inspection output confirms the cmake path below
# is correct (or replace with `RUN make static` if a Makefile target exists).
# RUN mkdir -p build && cd build && \
#     cmake .. -DCMAKE_BUILD_TYPE=Release \
#       -DCMAKE_TOOLCHAIN_FILE=/vcpkg/scripts/buildsystems/vcpkg.cmake \
#     && cmake --build . -j2

CMD ["/bin/bash"]
