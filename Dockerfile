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

# Found on the last inspection pass: a real Makefile exists at
# dave/libdave/cpp/Makefile, and there's no single root vcpkg.json --
# instead backend-specific manifests live under vcpkg-alts/<backend>/.
# libdave also vendors its own pinned copy of vcpkg at cpp/vcpkg/ rather
# than using whatever unpinned version we clone separately. Read the
# Makefile itself and list the backend options before guessing further.
RUN echo "=== Makefile content ===" && cat dave/libdave/cpp/Makefile 2>&1; \
    echo "=== vcpkg-alts backend options ===" && ls -la dave/libdave/cpp/vcpkg-alts/ 2>&1; \
    echo "=== cpp/ top-level contents ===" && ls -la dave/libdave/cpp/ 2>&1; \
    echo "=== is vcpkg vendored as its own submodule? ===" && git config --file dave/libdave/.gitmodules --get-regexp path 2>&1

# --- Full build (commented out for the inspection pass) ---
# Uncomment once Phase 3's inspection output confirms the cmake path below
# is correct (or replace with `RUN make static` if a Makefile target exists).
# RUN mkdir -p build && cd build && \
#     cmake .. -DCMAKE_BUILD_TYPE=Release \
#       -DCMAKE_TOOLCHAIN_FILE=/vcpkg/scripts/buildsystems/vcpkg.cmake \
#     && cmake --build . -j2

CMD ["/bin/bash"]
