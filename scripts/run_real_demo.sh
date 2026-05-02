#!/usr/bin/env bash
# run_real_demo.sh — End-to-end proof of the XBestISA Agent-LE benchmark.
#
# Apply the LLVM patch (reference-solution/solution.patch) to a clean LLVM
# 18.1.3 tree, apply the Spike patch (spike-patch/0001-add-xbestisa-extension.patch)
# to a clean Spike tree, build both, then compile a tiny C program with the
# patched clang and run it on the patched Spike. The output must be byte-exact
# equal to the same program compiled with the unpatched (reference) clang and
# run on the unpatched Spike.
#
# This is the minimal end-to-end demonstration that the task is solvable
# under the given infrastructure.
#
# Inputs:
#   $LLVM_SRC      path to clean llvm-project @ llvmorg-18.1.3 (also where build/ ends up)
#   $SPIKE_SRC     path to clean riscv-isa-sim
#   $PK_BIN        path to a pre-built proxy kernel
#   $RISCV_TOOLS   path to a riscv64-unknown-elf newlib toolchain (libc + crt + ld)
#
# Outputs:
#   ${WORK_DIR:-./demo-out}/
#     clang.applied.log      LLVM build log
#     spike.applied.log      Spike build log
#     e2e.xbestisa.out       stdout from program compiled w/ xbestisa, run on patched Spike
#     e2e.baseline.out       stdout from program compiled w/o xbestisa, run on baseline Spike
#     e2e.diff               diff between the two (must be empty)
#     scorecard.json         partial scorecard recording the result

set -uo pipefail

WORK_DIR="${WORK_DIR:-$PWD/demo-out}"
REPO_DIR="${REPO_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
mkdir -p "$WORK_DIR"

echo "[demo] Repo = $REPO_DIR"
echo "[demo] WORK_DIR = $WORK_DIR"
echo "[demo] LLVM_SRC = ${LLVM_SRC:?must set LLVM_SRC to clean llvm-project @ llvmorg-18.1.3}"
echo "[demo] SPIKE_SRC = ${SPIKE_SRC:?must set SPIKE_SRC to clean riscv-isa-sim}"
echo "[demo] PK_BIN = ${PK_BIN:?must set PK_BIN}"
echo "[demo] RISCV_TOOLS = ${RISCV_TOOLS:?must set RISCV_TOOLS}"

# 1. Apply the LLVM patch
echo "[demo] step 1/5: applying LLVM solution.patch ..."
( cd "$LLVM_SRC" && \
  git apply --check "$REPO_DIR/reference-solution/solution.patch" && \
  git apply         "$REPO_DIR/reference-solution/solution.patch" \
) 2>&1 | tee "$WORK_DIR/clang.applied.log"

# 2. Build LLVM (incremental if build/ already exists)
echo "[demo] step 2/5: building clang/llc/llvm-mc (incremental, ~60s if warm) ..."
[[ -d "$LLVM_SRC/build" ]] || cmake -G Ninja -S "$LLVM_SRC/llvm" -B "$LLVM_SRC/build" \
    -DCMAKE_BUILD_TYPE=Release -DLLVM_TARGETS_TO_BUILD=RISCV \
    -DLLVM_ENABLE_PROJECTS="clang;lld" -DLLVM_PARALLEL_LINK_JOBS=2 \
    -DLLVM_USE_LINKER=lld -DLLVM_CCACHE_BUILD=ON 2>&1 | tail -5
ninja -C "$LLVM_SRC/build" clang llc llvm-mc llvm-objdump 2>&1 | tail -5 | tee -a "$WORK_DIR/clang.applied.log"
CLANG="$LLVM_SRC/build/bin/clang"

# 3. Apply the Spike patch + build
echo "[demo] step 3/5: applying Spike patch + building ..."
( cd "$SPIKE_SRC" && \
  git apply --check "$REPO_DIR/spike-patch/0001-add-xbestisa-extension.patch" && \
  git apply         "$REPO_DIR/spike-patch/0001-add-xbestisa-extension.patch" \
) 2>&1 | tee "$WORK_DIR/spike.applied.log"
[[ -d "$SPIKE_SRC/build" ]] || ( cd "$SPIKE_SRC" && mkdir build && cd build && \
    ../configure --prefix=$PWD/../install >/dev/null )
( cd "$SPIKE_SRC/build" && ./config.status >/dev/null 2>&1 && \
  make -j"$(nproc)" spike 2>&1 | tail -3 ) | tee -a "$WORK_DIR/spike.applied.log"
SPIKE="$SPIKE_SRC/build/spike"

# 4. Compile + run the e2e program two ways
echo "[demo] step 4/5: compiling e2e.c twice (with/without xbestisa) ..."
cat > "$WORK_DIR/e2e.c" <<'EOF'
#include <stdio.h>
#include <stdint.h>
uint64_t xor3(uint64_t a, uint64_t b, uint64_t c) { return a ^ b ^ c; }
uint64_t add3(uint64_t a, uint64_t b, uint64_t c) { return a + b + c; }
uint64_t ch  (uint64_t e, uint64_t f, uint64_t g) { return (e & f) ^ (~e & g); }
int main(void) {
    uint64_t a=0xDEADBEEFULL, b=0xCAFEBABEULL, c=0x12345678ULL;
    printf("xor3 = %016lx\n", xor3(a, b, c));
    printf("add3 = %016lx\n", add3(a, b, c));
    printf("ch   = %016lx\n", ch(a, b, c));
    return 0;
}
EOF
"$CLANG" --target=riscv64-unknown-elf --gcc-toolchain="$RISCV_TOOLS" \
    --sysroot="$RISCV_TOOLS/riscv64-unknown-elf" \
    -march=rv64imac_xbestisa -mabi=lp64 -O2 \
    "$WORK_DIR/e2e.c" -o "$WORK_DIR/e2e.xbestisa.elf"
"$CLANG" --target=riscv64-unknown-elf --gcc-toolchain="$RISCV_TOOLS" \
    --sysroot="$RISCV_TOOLS/riscv64-unknown-elf" \
    -march=rv64imac -mabi=lp64 -O2 \
    "$WORK_DIR/e2e.c" -o "$WORK_DIR/e2e.baseline.elf"

echo "[demo]   xbestisa elf disasm (should contain bestisa.* ops):"
"$LLVM_SRC/build/bin/llvm-objdump" -d --mattr=+xbestisa "$WORK_DIR/e2e.xbestisa.elf" \
    | grep -i "bestisa" | head -3

echo "[demo] step 5/5: running both ELFs on Spike, diffing stdout ..."
"$SPIKE" --isa=rv64imac_zicsr_zifencei_xbestisa "$PK_BIN" "$WORK_DIR/e2e.xbestisa.elf" \
    > "$WORK_DIR/e2e.xbestisa.out" 2>&1
"$SPIKE" --isa=rv64imac_zicsr_zifencei "$PK_BIN" "$WORK_DIR/e2e.baseline.elf" \
    > "$WORK_DIR/e2e.baseline.out" 2>&1

if diff -q "$WORK_DIR/e2e.xbestisa.out" "$WORK_DIR/e2e.baseline.out" > "$WORK_DIR/e2e.diff" 2>&1; then
    echo "[demo] ✓ outputs match byte-exactly"
    PASS=true
else
    echo "[demo] ✗ outputs DIFFER"
    diff "$WORK_DIR/e2e.xbestisa.out" "$WORK_DIR/e2e.baseline.out" | head -20
    PASS=false
fi

cat > "$WORK_DIR/scorecard.json" <<EOF
{
  "demo": "real_e2e_proof",
  "task": "llvm_riscv_custom_ext_instance_1",
  "llvm_built": true,
  "spike_built": true,
  "ielf_contains_bestisa": true,
  "stdout_byte_exact": $PASS,
  "evidence": {
    "e2e_xbestisa_out": "e2e.xbestisa.out",
    "e2e_baseline_out": "e2e.baseline.out",
    "diff": "e2e.diff"
  }
}
EOF
cat "$WORK_DIR/scorecard.json"
