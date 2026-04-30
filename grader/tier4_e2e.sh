#!/usr/bin/env bash
# tier4_e2e.sh — Tier 4: end-to-end llvm-test-suite SingleSource subset on Spike. 10 pts.
# Build subset twice (agent's clang with xbestisa, reference clang baseline),
# run each binary on Spike, compare stdout byte-exactly.
set -uo pipefail

WORK_DIR="${WORK_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
LLVM_BUILD="${LLVM_BUILD:-$WORK_DIR/llvm-project/build}"
CLANG="$LLVM_BUILD/bin/clang"
CLANGXX="$LLVM_BUILD/bin/clang++"
REF_CLANG="${REF_CLANG:-$WORK_DIR/reference-toolchain/bin/clang}"
REF_CLANGXX="${REF_CLANGXX:-$WORK_DIR/reference-toolchain/bin/clang++}"
SPIKE="${SPIKE:-$WORK_DIR/spike/install/bin/spike}"
PK="${PK:-$WORK_DIR/spike/install/riscv64-unknown-elf/bin/pk}"
TS_SRC="${TS_SRC:-$WORK_DIR/llvm-test-suite}"
TMP="$WORK_DIR/grader-tmp/tier4"
mkdir -p "$TMP"

SUBSET_RE='SingleSource/Benchmarks/(Misc|Stanford|Shootout)'

build_suite() {
    local label="$1" cc="$2" cxx="$3" cflags="$4" isa="$5"
    local bdir="$TMP/build-$label"
    mkdir -p "$bdir"
    cmake -G Ninja -S "$TS_SRC" -B "$bdir" \
        -DCMAKE_C_COMPILER="$cc" \
        -DCMAKE_CXX_COMPILER="$cxx" \
        -DCMAKE_C_FLAGS="$cflags" \
        -DCMAKE_CXX_FLAGS="$cflags" \
        -DCMAKE_SYSTEM_NAME=Generic \
        -DCMAKE_CROSSCOMPILING=ON \
        -DTEST_SUITE_RUN_BENCHMARKS=OFF \
        -DTEST_SUITE_SUBDIRS="SingleSource/Benchmarks/Misc;SingleSource/Benchmarks/Stanford;SingleSource/Benchmarks/Shootout" \
        >"$TMP/cmake-$label.log" 2>&1 || return 1
    ninja -C "$bdir" >"$TMP/ninja-$label.log" 2>&1 || true   # tolerate partial build
}

run_one() {
    local elf="$1" isa="$2" out="$3"
    "$SPIKE" --isa="$isa" "$PK" "$elf" >"$out" 2>&1 || true
}

build_suite agent "$CLANG" "$CLANGXX" "-O2 -march=rv64gc_xbestisa" "rv64gc_xbestisa" || true
build_suite ref   "$REF_CLANG" "$REF_CLANGXX" "-O2 -march=rv64gc"           "rv64gc"           || true

matching=0
total=0
fail_log="$TMP/failures.log"
: > "$fail_log"

while read -r elf_a; do
    [[ -x "$elf_a" ]] || continue
    rel="${elf_a#$TMP/build-agent/}"
    elf_r="$TMP/build-ref/$rel"
    [[ -x "$elf_r" ]] || continue
    total=$((total+1))
    out_a="$TMP/run-agent-$(basename "$rel").out"
    out_r="$TMP/run-ref-$(basename "$rel").out"
    run_one "$elf_a" rv64gc_xbestisa "$out_a"
    run_one "$elf_r" rv64gc          "$out_r"
    if diff -q "$out_a" "$out_r" >/dev/null 2>&1; then
        matching=$((matching+1))
    else
        echo "[$rel] differs" >> "$fail_log"
    fi
done < <(find "$TMP/build-agent" -type f -executable 2>/dev/null | grep -E "$SUBSET_RE")

score=0
if (( total > 0 )); then
    pct=$(( 100 * matching / total ))
    if (( pct >= 95 )); then
        score=10
    else
        score=$(( 10 * matching / total ))
    fi
fi

cat <<EOF
{
  "score": $score,
  "max": 10,
  "details": {
    "matching": $matching,
    "total":    $total,
    "subset":   "SingleSource/Benchmarks/{Misc,Stanford,Shootout}",
    "fail_log": "grader-tmp/tier4/failures.log"
  }
}
EOF
