#!/usr/bin/env bash
# grade.sh — Agent-LE XBestISA top-level grader.
# Runs all 4 tiers, aggregates a deterministic scorecard.json.
#
# Usage:   bash grader/grade.sh [--tier 0|1|2|3|4|all]  [--keep-tmp]
# Env:     WORK_DIR (default: repo root), LLVM_BUILD (default: $WORK_DIR/llvm-project/build)

set -uo pipefail

WORK_DIR="${WORK_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
LLVM_BUILD="${LLVM_BUILD:-$WORK_DIR/llvm-project/build}"
GRADER_DIR="$WORK_DIR/grader"
TMP_DIR="$WORK_DIR/grader-tmp"
SCORECARD="$WORK_DIR/scorecard.json"
TIER_FILTER="${TIER_FILTER:-all}"
KEEP_TMP=0

# --- arg parsing ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --tier)      TIER_FILTER="$2"; shift 2 ;;
        --keep-tmp)  KEEP_TMP=1; shift ;;
        -h|--help)
            sed -n '2,7p' "$0" | sed 's/^# //'
            exit 0 ;;
        *) echo "unknown arg: $1" >&2; exit 2 ;;
    esac
done

mkdir -p "$TMP_DIR"
[[ "$KEEP_TMP" == "0" ]] && trap 'rm -rf "$TMP_DIR"' EXIT

run_tier() {
    local tier="$1" name="$2"
    if [[ "$TIER_FILTER" != "all" && "$TIER_FILTER" != "$tier" ]]; then
        echo "{\"score\": null, \"max\": null, \"skipped\": true}"
        return 0
    fi
    echo "[grade.sh] === Tier $tier: $name ===" >&2
    bash "$GRADER_DIR/tier${tier}_${name}.sh" 2>"$TMP_DIR/tier${tier}.stderr"
}

# --- 0. Oracle integrity check (always runs) ---
echo "[grade.sh] Verifying oracle integrity..." >&2
if ! bash "$WORK_DIR/scripts/verify_oracle.sh" >"$TMP_DIR/oracle.log" 2>&1; then
    cat "$TMP_DIR/oracle.log" >&2
    echo '{"oracle_sha256_ok": false, "fatal": "oracle tampering detected", "total": 0, "pass": false}' \
        | tee "$SCORECARD"
    exit 99
fi

# --- 1. Run each tier, capture JSON fragments ---
T0=$(run_tier 0 build)
T1=$(run_tier 1 lit)
T2=$(run_tier 2 spike)
T3a=$(run_tier 3a isel)
T3b=$(run_tier 3b noregress)
T4=$(run_tier 4 e2e)

# --- 2. Aggregate via score.py ---
python3 "$GRADER_DIR/score.py" \
    --tier0 "$T0" \
    --tier1 "$T1" \
    --tier2 "$T2" \
    --tier3a "$T3a" \
    --tier3b "$T3b" \
    --tier4 "$T4" \
    --task "llvm_riscv_custom_ext_instance_1" \
    --output "$SCORECARD"

echo "[grade.sh] === scorecard.json ===" >&2
cat "$SCORECARD"
