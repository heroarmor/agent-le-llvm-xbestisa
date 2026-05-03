# Agent-LE XBestISA — reproducible build environment.
# Pinned to ubuntu:24.04 by digest; all source pins are explicit commits.
#
# Build:  docker build -t agent-le-xbestisa:1.0 -f docker/Dockerfile .
# Size:   ~12 GB compressed, ~25 GB uncompressed
# Build wall-time: ~45 minutes on 16 vCPU

FROM ubuntu:24.04

# Pinned commit SHAs (verified working as of 2026-05-01).
ARG LLVM_TAG=llvmorg-18.1.3
ARG LLVM_COMMIT=c13b7485b87909fcf739f62cfa382b55407433c0
ARG SPIKE_COMMIT=0ad45926ac6f42d0d39e936abf4ab1cb9bdc5086
ARG PK_COMMIT=9c61d29846d8521d9487a57739330f9682d5b542
ARG TEST_SUITE_TAG=llvmorg-18.1.3
ARG DEBIAN_FRONTEND=noninteractive

# 1. Base toolchain
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake ninja-build clang lld ccache python3 python3-pip \
    git ca-certificates curl wget xz-utils \
    gcc-riscv64-linux-gnu g++-riscv64-linux-gnu \
    libgmp-dev libmpfr-dev libmpc-dev libisl-dev \
    autoconf automake libtool device-tree-compiler \
    bison flex texinfo gperf libncurses-dev \
    && rm -rf /var/lib/apt/lists/*

ENV CCACHE_DIR=/work/.ccache
ENV CCACHE_MAXSIZE=30G
ENV PATH=/usr/lib/ccache:$PATH

WORKDIR /work

# 2. Clone pinned LLVM
RUN git clone --depth 1 --branch ${LLVM_TAG} \
    https://github.com/llvm/llvm-project.git llvm-project \
    && cd llvm-project && git rev-parse HEAD > /work/llvm-project.sha

# 3. Pre-build LLVM (warm ccache)
RUN cmake -G Ninja -S llvm-project/llvm -B llvm-project/build \
        -DCMAKE_BUILD_TYPE=Release \
        -DLLVM_TARGETS_TO_BUILD=RISCV \
        -DLLVM_ENABLE_PROJECTS="clang;lld" \
        -DLLVM_PARALLEL_LINK_JOBS=2 \
        -DLLVM_USE_LINKER=lld \
        -DLLVM_CCACHE_BUILD=ON \
        -DLLVM_INCLUDE_TESTS=ON \
        -DLLVM_BUILD_TESTS=ON \
        -DLLVM_INSTALL_UTILS=ON \
        -DLLVM_OPTIMIZED_TABLEGEN=ON \
    && ninja -C llvm-project/build clang llc llvm-mc llvm-tblgen FileCheck llvm-objdump

# 4. Build a SECOND, unmodified reference toolchain (for Tier 2 / 3b reference compares)
RUN cp -r llvm-project reference-llvm-project \
    && cmake -G Ninja -S reference-llvm-project/llvm -B reference-llvm-project/build \
        -DCMAKE_BUILD_TYPE=Release \
        -DLLVM_TARGETS_TO_BUILD=RISCV \
        -DLLVM_ENABLE_PROJECTS="clang;lld" \
        -DLLVM_PARALLEL_LINK_JOBS=2 \
        -DLLVM_USE_LINKER=lld \
        -DLLVM_CCACHE_BUILD=ON \
        -DCMAKE_INSTALL_PREFIX=/work/reference-toolchain \
    && ninja -C reference-llvm-project/build install \
    && rm -rf reference-llvm-project   # keep only the installed binaries

# 5. Spike (oracle) — clone at pinned SHA, apply patch, build, hash
COPY spike-patch /tmp/spike-patch
RUN git clone https://github.com/riscv-software-src/riscv-isa-sim.git spike \
    && cd spike && git checkout ${SPIKE_COMMIT} \
    && git apply /tmp/spike-patch/0001-add-xbestisa-extension.patch \
    && mkdir -p build && cd build \
    && ../configure --prefix=/work/spike/install \
    && make -j$(nproc) spike spike-dasm \
    && make install \
    && sha256sum /work/spike/install/bin/spike > /work/spike/built-binary.sha256

# 6. riscv-pk (proxy kernel) at pinned SHA, built for rv64imac_zicsr_zifencei
RUN git clone https://github.com/riscv-software-src/riscv-pk.git \
    && cd riscv-pk && git checkout ${PK_COMMIT} \
    && mkdir build && cd build \
    && ../configure --prefix=/work/spike/install --host=riscv64-unknown-elf \
        --with-arch=rv64imac_zicsr_zifencei --with-abi=lp64 \
    && make pk -j$(nproc) \
    && cp pk /work/spike/install/bin/pk

# 7. llvm-test-suite
RUN git clone --depth 1 --branch ${TEST_SUITE_TAG} \
    https://github.com/llvm/llvm-test-suite.git

# 8. Copy the benchmark harness into the image
COPY README.md TASK.md LICENSE /work/
COPY docs /work/docs
COPY grader /work/grader
COPY tests /work/tests
COPY examples /work/examples
COPY reference-solution /work/reference-solution
COPY scripts /work/scripts

# 9. Sanity check: oracle hash matches
RUN bash /work/scripts/verify_oracle.sh

WORKDIR /work
CMD ["bash"]
