#!/usr/bin/env bash
# tier0_build.sh — Tier 0: build sanity. Emits JSON to stdout.
set -uo pipefail

WORK_DIR="${WORK_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
LLVM_BUILD="${LLVM_BUILD:-$WORK_DIR/llvm-project/build}"
TMP="$WORK_DIR/grader-tmp"
mkdir -p "$TMP"
LOG="$TMP/tier0.log"

ok=1
{
    echo "[tier0] Building clang, llc, llvm-mc, llvm-tblgen..."
    cmake --build "$LLVM_BUILD" --target clang llc llvm-mc llvm-tblgen 2>&1 \
        || ok=0
} > "$LOG" 2>&1

# Check the agent didn't modify forbidden paths.
diff_log="$TMP/forbidden_paths.log"
if [[ -d "$WORK_DIR/llvm-project/.git" ]]; then
    git -C "$WORK_DIR/llvm-project" diff --name-only HEAD 2>/dev/null \
        | grep -E '^(test/CodeGen/RISCV/|test/MC/RISCV/)' \
        | while read -r f; do
            if grep -qx "llvm-project/$f" "$WORK_DIR/tests/regression/baseline_lit.txt" 2>/dev/null; then
                echo "FORBIDDEN: agent modified pre-existing baseline test: $f"
                ok=0
            fi
        done > "$diff_log"
    [[ -s "$diff_log" ]] && ok=0
fi

# Verify outside-llvm-project paths unmodified
forbidden_outside_log="$TMP/forbidden_outside.log"
for d in spike spike-patch llvm-test-suite tests docs examples reference-toolchain grader scripts; do
    if [[ -d "$WORK_DIR/$d/.git-watch" ]]; then
        git -C "$WORK_DIR/$d" status --porcelain 2>/dev/null | head -5 >> "$forbidden_outside_log"
    fi
done
[[ -s "$forbidden_outside_log" ]] && ok=0

score=0
if [[ "$ok" == "1" ]]; then score=5; fi

cat <<EOF
{"score": $score, "max": 5, "details": {"build_ok": $ok, "log": "grader-tmp/tier0.log"}}
EOF
