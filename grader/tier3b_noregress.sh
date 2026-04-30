#!/usr/bin/env bash
# tier3b_noregress.sh — Tier 3b: no opcode-set regression. 5 pts.
# Compile 50 baseline .c files with both agent and reference clang at
# -march=rv64gc (no extension), and verify identical opcode-mnemonic histograms.
set -uo pipefail

WORK_DIR="${WORK_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
LLVM_BUILD="${LLVM_BUILD:-$WORK_DIR/llvm-project/build}"
CLANG="$LLVM_BUILD/bin/clang"
REF_CLANG="${REF_CLANG:-$WORK_DIR/reference-toolchain/bin/clang}"
OBJDUMP="$LLVM_BUILD/bin/llvm-objdump"
TMP="$WORK_DIR/grader-tmp/tier3b"
mkdir -p "$TMP"

CFLAGS=(--target=riscv64-unknown-elf -march=rv64gc -O2 -c)

matching=0
total=0
fail_log="$TMP/failures.log"
: > "$fail_log"

opcode_histogram() {
    "$OBJDUMP" -d "$1" 2>/dev/null \
        | awk '/^[[:space:]]+[0-9a-f]+:/ { print $3 }' \
        | sort | uniq -c | awk '{print $2, $1}' | sort
}

for src in "$WORK_DIR"/tests/regression/baseline_codegen/*.c; do
    [[ -f "$src" ]] || continue
    total=$((total+1))
    name=$(basename "$src" .c)
    obj_a="$TMP/${name}.agent.o"
    obj_r="$TMP/${name}.ref.o"

    if ! "$CLANG"     "${CFLAGS[@]}" "$src" -o "$obj_a" 2>>"$fail_log"; then
        echo "[$name] agent compile failed" >> "$fail_log"; continue; fi
    if ! "$REF_CLANG" "${CFLAGS[@]}" "$src" -o "$obj_r" 2>>"$fail_log"; then
        echo "[$name] reference compile failed" >> "$fail_log"; continue; fi

    if diff -q <(opcode_histogram "$obj_a") <(opcode_histogram "$obj_r") >/dev/null 2>&1; then
        matching=$((matching+1))
    else
        echo "[$name] opcode histogram differs" >> "$fail_log"
    fi
done

score=0
if (( total > 0 )); then
    score=$(( 5 * matching / total ))
fi

cat <<EOF
{
  "score": $score,
  "max": 5,
  "details": {
    "matching": $matching,
    "total":    $total,
    "fail_log": "grader-tmp/tier3b/failures.log"
  }
}
EOF
