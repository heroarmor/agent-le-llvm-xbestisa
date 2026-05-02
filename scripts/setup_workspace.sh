#!/usr/bin/env bash
# setup_workspace.sh — local-host (non-Docker) setup helper.
# Use this only if you can't or don't want to use the Docker image.
#
# Assumes Ubuntu 24.04 with apt available. Will install ~3 GB of packages.
set -euo pipefail

LLVM_TAG="llvmorg-18.1.3"
LLVM_COMMIT="ae96967dcb2001160069230bbb94d549384b28c1"
SPIKE_COMMIT="0ad45926ac6f42d0d39e936abf4ab1cb9bdc5086"
PK_COMMIT="9c61d29846d8521d9487a57739330f9682d5b542"
TEST_SUITE_TAG="llvmorg-18.1.3"

WORK_DIR="${WORK_DIR:-$PWD}"

echo "[setup] installing apt packages (sudo required)..."
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
    build-essential cmake ninja-build clang lld ccache python3 \
    git ca-certificates curl \
    gcc-riscv64-linux-gnu g++-riscv64-linux-gnu \
    libgmp-dev libmpfr-dev libmpc-dev \
    autoconf automake libtool device-tree-compiler

echo "[setup] cloning LLVM ${LLVM_TAG} (commit ${LLVM_COMMIT:0:12})..."
[[ -d "$WORK_DIR/llvm-project" ]] \
    || git clone --depth 1 --branch "$LLVM_TAG" \
        https://github.com/llvm/llvm-project.git "$WORK_DIR/llvm-project"
ACTUAL_LLVM_SHA="$(git -C "$WORK_DIR/llvm-project" rev-parse HEAD)"
[[ "$ACTUAL_LLVM_SHA" == "$LLVM_COMMIT" ]] \
    || echo "[setup] WARN: LLVM SHA mismatch (got $ACTUAL_LLVM_SHA, expected $LLVM_COMMIT)"

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

echo "[setup] cloning + patching Spike at pinned SHA..."
[[ -d "$WORK_DIR/spike" ]] \
    || git clone https://github.com/riscv-software-src/riscv-isa-sim.git "$WORK_DIR/spike"
(
    cd "$WORK_DIR/spike"
    git fetch --depth 1 origin "$SPIKE_COMMIT" 2>/dev/null || true
    git checkout "$SPIKE_COMMIT"
    git apply "$WORK_DIR/spike-patch/0001-add-xbestisa-extension.patch"
    mkdir -p build && cd build
    ../configure --prefix="$WORK_DIR/spike/install"
    make -j"$(nproc)" spike spike-dasm
    make install
)

echo "[setup] cloning + building pk at pinned SHA..."
[[ -d "$WORK_DIR/riscv-pk" ]] \
    || git clone https://github.com/riscv-software-src/riscv-pk.git "$WORK_DIR/riscv-pk"
(
    cd "$WORK_DIR/riscv-pk"
    git fetch --depth 1 origin "$PK_COMMIT" 2>/dev/null || true
    git checkout "$PK_COMMIT"
    mkdir -p build && cd build
    ../configure --prefix="$WORK_DIR/spike/install" --host=riscv64-unknown-elf \
        --with-arch=rv64imac_zicsr_zifencei --with-abi=lp64
    make pk -j"$(nproc)"
    cp pk "$WORK_DIR/spike/install/bin/pk"
)

echo "[setup] cloning llvm-test-suite..."
[[ -d "$WORK_DIR/llvm-test-suite" ]] \
    || git clone --depth 1 --branch "$TEST_SUITE_TAG" \
        https://github.com/llvm/llvm-test-suite.git "$WORK_DIR/llvm-test-suite"

echo "[setup] verifying oracle..."
bash "$WORK_DIR/scripts/verify_oracle.sh"

echo "[setup] DONE. Run 'bash grader/grade.sh' to grade your submission."
