#!/usr/bin/env bash
# setup_workspace.sh — local-host (non-Docker) setup helper.
# Use this only if you can't or don't want to use the Docker image.
#
# Assumes Ubuntu 24.04 with apt available. Will install ~3 GB of packages.
set -euo pipefail

LLVM_TAG="llvmorg-22.1.0"
SPIKE_COMMIT="<TBD-pin-at-package-time>"
TEST_SUITE_TAG="llvmorg-22.1.0"

WORK_DIR="${WORK_DIR:-$PWD}"

echo "[setup] installing apt packages (sudo required)..."
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
    build-essential cmake ninja-build clang lld ccache python3 \
    git ca-certificates curl \
    gcc-riscv64-linux-gnu g++-riscv64-linux-gnu \
    libgmp-dev libmpfr-dev libmpc-dev \
    autoconf automake libtool device-tree-compiler

echo "[setup] cloning LLVM ${LLVM_TAG}..."
[[ -d "$WORK_DIR/llvm-project" ]] \
    || git clone --depth 1 --branch "$LLVM_TAG" \
        https://github.com/llvm/llvm-project.git "$WORK_DIR/llvm-project"

echo "[setup] configuring LLVM build..."
cmake -G Ninja -S "$WORK_DIR/llvm-project/llvm" -B "$WORK_DIR/llvm-project/build" \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_TARGETS_TO_BUILD=RISCV \
    -DLLVM_ENABLE_PROJECTS="clang;lld" \
    -DLLVM_PARALLEL_LINK_JOBS=2 \
    -DLLVM_USE_LINKER=lld \
    -DLLVM_CCACHE_BUILD=ON \
    -DLLVM_OPTIMIZED_TABLEGEN=ON

echo "[setup] building LLVM (cold build, ~30 min)..."
ninja -C "$WORK_DIR/llvm-project/build" clang llc llvm-mc llvm-tblgen FileCheck llvm-objdump

echo "[setup] cloning + patching Spike..."
[[ -d "$WORK_DIR/spike" ]] \
    || git clone https://github.com/riscv-software-src/riscv-isa-sim.git "$WORK_DIR/spike"
(
    cd "$WORK_DIR/spike"
    git checkout "$SPIKE_COMMIT" || echo "WARN: pinned commit not available, using HEAD"
    patch -p1 < "$WORK_DIR/spike-patch/0001-add-xbestisa-extension.patch" || true
    mkdir -p build && cd build
    ../configure --prefix="$WORK_DIR/spike/install" --with-isa=rv64gc_xbestisa
    make -j"$(nproc)" install
)

echo "[setup] cloning llvm-test-suite..."
[[ -d "$WORK_DIR/llvm-test-suite" ]] \
    || git clone --depth 1 --branch "$TEST_SUITE_TAG" \
        https://github.com/llvm/llvm-test-suite.git "$WORK_DIR/llvm-test-suite"

echo "[setup] verifying oracle..."
bash "$WORK_DIR/scripts/verify_oracle.sh"

echo "[setup] DONE. Run 'bash grader/grade.sh' to grade your submission."
