#!/usr/bin/env bash
# tier1_lit.sh — Tier 1: lit regression + new MC + new CodeGen CHECK lines.
# Subdivision:
#   1a (15 pts): pre-existing lit tests in baseline_lit.txt all pass
#   1b (10 pts): 20 new MC valid+invalid tests pass with byte-exact encoding
#   1c (5 pts):  10 new CodeGen .ll FileCheck tests pass
set -uo pipefail

WORK_DIR="${WORK_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
LLVM_BUILD="${LLVM_BUILD:-$WORK_DIR/llvm-project/build}"
LLVM_MC="$LLVM_BUILD/bin/llvm-mc"
LLC="$LLVM_BUILD/bin/llc"
FILECHECK="$LLVM_BUILD/bin/FileCheck"
LIT="$LLVM_BUILD/bin/llvm-lit"
OBJDUMP="$LLVM_BUILD/bin/llvm-objdump"
TMP="$WORK_DIR/grader-tmp/tier1"
mkdir -p "$TMP"

# --- 1a: baseline lit ---
baseline_total=0
baseline_pass=0
if [[ -f "$WORK_DIR/tests/regression/baseline_lit.txt" ]]; then
    while read -r t; do
        [[ -z "$t" || "$t" =~ ^# ]] && continue
        baseline_total=$((baseline_total+1))
        if "$LIT" --order=lexical -j1 -q "$WORK_DIR/llvm-project/$t" 2>/dev/null >/dev/null; then
            baseline_pass=$((baseline_pass+1))
        fi
    done < "$WORK_DIR/tests/regression/baseline_lit.txt"
fi
score_1a=0
if (( baseline_total > 0 )); then
    score_1a=$(( 15 * baseline_pass / baseline_total ))
fi

# --- 1b: MC valid + invalid ---
mc_pass=0
mc_total=0
for f in "$WORK_DIR"/tests/mc/valid/*.s; do
    [[ -f "$f" ]] || continue
    mc_total=$((mc_total+1))
    base="${f%.s}"
    expected="$base.expected"
    [[ -f "$expected" ]] || continue
    actual=$("$LLVM_MC" -triple=riscv64 -mattr=+xbestisa -show-encoding "$f" 2>/dev/null || true)
    if diff -q <(echo "$actual") "$expected" >/dev/null 2>&1; then
        mc_pass=$((mc_pass+1))
    fi
done
for f in "$WORK_DIR"/tests/mc/invalid/*.s; do
    [[ -f "$f" ]] || continue
    mc_total=$((mc_total+1))
    base="${f%.s}"
    expected_err="$base.expected_err"
    [[ -f "$expected_err" ]] || continue
    err=$("$LLVM_MC" -triple=riscv64 -mattr=+xbestisa "$f" 2>&1 >/dev/null || true)
    expected_substr=$(cat "$expected_err")
    if echo "$err" | grep -qF "$expected_substr"; then
        mc_pass=$((mc_pass+1))
    fi
done
score_1b=0
if (( mc_total > 0 )); then
    score_1b=$(( 10 * mc_pass / mc_total ))
fi

# --- 1c: CodeGen .ll FileCheck ---
ll_pass=0
ll_total=0
for f in "$WORK_DIR"/tests/codegen/llcheck/*.ll; do
    [[ -f "$f" ]] || continue
    ll_total=$((ll_total+1))
    if "$LLC" -mtriple=riscv64 -mattr=+xbestisa -O2 "$f" -o - 2>/dev/null \
         | "$FILECHECK" "$f" 2>/dev/null; then
        ll_pass=$((ll_pass+1))
    fi
done
score_1c=0
if (( ll_total > 0 )); then
    score_1c=$(( 5 * ll_pass / ll_total ))
fi

total=$(( score_1a + score_1b + score_1c ))

cat <<EOF
{
  "score": $total,
  "max": 30,
  "details": {
    "1a_baseline_lit":  {"score": $score_1a, "max": 15, "passing": $baseline_pass, "total": $baseline_total},
    "1b_mc":            {"score": $score_1b, "max": 10, "passing": $mc_pass, "total": $mc_total},
    "1c_codegen_check": {"score": $score_1c, "max": 5,  "passing": $ll_pass, "total": $ll_total}
  }
}
EOF
