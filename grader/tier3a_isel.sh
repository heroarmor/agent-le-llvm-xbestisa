#!/usr/bin/env bash
# tier3a_isel.sh — Tier 3a: instruction selection from natural C. 15 pts.
# For each .c snippet, compile and grep for the expected mnemonic count.
set -uo pipefail

WORK_DIR="${WORK_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
LLVM_BUILD="${LLVM_BUILD:-$WORK_DIR/llvm-project/build}"
CLANG="$LLVM_BUILD/bin/clang"
TMP="$WORK_DIR/grader-tmp/tier3a"
mkdir -p "$TMP"

pass=0
total=0
fail_log="$TMP/failures.log"
: > "$fail_log"

for src in "$WORK_DIR"/tests/codegen/*.c; do
    [[ -f "$src" ]] || continue
    total=$((total+1))
    name=$(basename "$src" .c)
    expected_count_file="${src%.c}.expected_count"
    [[ -f "$expected_count_file" ]] || { echo "[$name] missing .expected_count" >> "$fail_log"; continue; }

    read -r mnemonic min_count < "$expected_count_file"
    asm="$TMP/${name}.s"
    if ! "$CLANG" --target=riscv64-unknown-elf -march=rv64gc_xbestisa -O2 -S "$src" -o "$asm" 2>>"$fail_log"; then
        echo "[$name] compile failed" >> "$fail_log"; continue
    fi
    actual_count=$(grep -c "\b${mnemonic}\b" "$asm" || true)
    if (( actual_count >= min_count )); then
        pass=$((pass+1))
    else
        echo "[$name] mnemonic '$mnemonic' count=$actual_count < expected $min_count" >> "$fail_log"
    fi
done

# 1.5 pts each, max 15
score=$(( (pass * 30) / 20 ))   # = pass * 1.5, integer math
[[ "$score" -gt 15 ]] && score=15

cat <<EOF
{
  "score": $score,
  "max": 15,
  "details": {
    "snippets_passing": $pass,
    "snippets_total":   $total,
    "fail_log":         "grader-tmp/tier3a/failures.log"
  }
}
EOF
