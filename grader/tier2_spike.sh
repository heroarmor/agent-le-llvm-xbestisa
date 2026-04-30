#!/usr/bin/env bash
# tier2_spike.sh — Tier 2: differential execution on Spike. 35 pts.
# For each program in tests/correctness/, compile with both agent's clang and
# the unmodified reference clang, run on Spike, compare stdout byte-exactly.
set -uo pipefail

WORK_DIR="${WORK_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
LLVM_BUILD="${LLVM_BUILD:-$WORK_DIR/llvm-project/build}"
CLANG="$LLVM_BUILD/bin/clang"
REF_CLANG="${REF_CLANG:-$WORK_DIR/reference-toolchain/bin/clang}"
SPIKE="${SPIKE:-$WORK_DIR/spike/install/bin/spike}"
PK="${PK:-$WORK_DIR/spike/install/riscv64-unknown-elf/bin/pk}"
TMP="$WORK_DIR/grader-tmp/tier2"
mkdir -p "$TMP"

CFLAGS_AGENT=(--target=riscv64-unknown-elf -march=rv64gc_xbestisa -O2)
CFLAGS_REF=(--target=riscv64-unknown-elf -march=rv64gc -O2)

pass=0
total=0
fail_log="$TMP/failures.log"
: > "$fail_log"

for src in "$WORK_DIR"/tests/correctness/*.c; do
    [[ -f "$src" ]] || continue
    total=$((total+1))
    name=$(basename "$src" .c)
    elf_a="$TMP/${name}.xbestisa.elf"
    elf_r="$TMP/${name}.baseline.elf"
    out_a="$TMP/${name}.xbestisa.out"
    out_r="$TMP/${name}.baseline.out"

    if ! "$CLANG"     "${CFLAGS_AGENT[@]}" "$src" -o "$elf_a" 2>>"$fail_log"; then
        echo "[$name] agent compile failed" >> "$fail_log"; continue; fi
    if ! "$REF_CLANG" "${CFLAGS_REF[@]}"   "$src" -o "$elf_r" 2>>"$fail_log"; then
        echo "[$name] reference compile failed" >> "$fail_log"; continue; fi
    if ! "$SPIKE" --isa=rv64gc_xbestisa "$PK" "$elf_a" >"$out_a" 2>&1; then
        echo "[$name] agent spike failed" >> "$fail_log"; continue; fi
    if ! "$SPIKE" --isa=rv64gc           "$PK" "$elf_r" >"$out_r" 2>&1; then
        echo "[$name] reference spike failed" >> "$fail_log"; continue; fi

    if diff -q "$out_a" "$out_r" >/dev/null 2>&1; then
        pass=$((pass+1))
    else
        echo "[$name] stdout differs" >> "$fail_log"
    fi
done

bonus=0
[[ "$pass" == "$total" && "$total" -ge 30 ]] && bonus=5
score=$(( pass + bonus ))
[[ "$score" -gt 35 ]] && score=35

cat <<EOF
{
  "score": $score,
  "max": 35,
  "details": {
    "programs_passing": $pass,
    "programs_total":   $total,
    "bonus":            $bonus,
    "fail_log":         "grader-tmp/tier2/failures.log"
  }
}
EOF
