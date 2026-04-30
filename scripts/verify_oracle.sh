#!/usr/bin/env bash
# verify_oracle.sh — verifies the Spike oracle binary and frozen test corpus
# have not been tampered with. Called at the start of every grade.sh run.
set -uo pipefail

WORK_DIR="${WORK_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
SPIKE_BIN="${SPIKE_BIN:-$WORK_DIR/spike/install/bin/spike}"

fail() { echo "VERIFY FAIL: $*" >&2; exit 1; }

# 1. Spike binary hash check
if [[ -f "$WORK_DIR/spike/built-binary.sha256" ]]; then
    expected=$(awk '{print $1}' "$WORK_DIR/spike/built-binary.sha256")
    actual=$(sha256sum "$SPIKE_BIN" | awk '{print $1}')
    [[ "$expected" == "$actual" ]] || fail "Spike binary hash mismatch: expected $expected, got $actual"
else
    echo "WARN: spike/built-binary.sha256 missing — skipping oracle hash check (dev mode)" >&2
fi

# 2. Manifest checks for sealed dirs
check_manifest() {
    local dir="$1"
    local manifest="$dir/MANIFEST.sha256"
    [[ -f "$manifest" ]] || return 0     # missing manifest = dev mode, skip
    while read -r expected_hash relpath; do
        [[ "$expected_hash" =~ ^# ]] && continue
        [[ -z "$expected_hash" ]] && continue
        # Skip placeholder zero-hashes (used in this template repo)
        [[ "$expected_hash" =~ ^0+$ ]] && continue
        local file="$dir/$relpath"
        [[ -f "$file" ]] || fail "Sealed file missing: $file"
        local actual_hash
        actual_hash=$(sha256sum "$file" | awk '{print $1}')
        [[ "$expected_hash" == "$actual_hash" ]] \
            || fail "Tampered file: $file (expected $expected_hash, got $actual_hash)"
    done < "$manifest"
}

check_manifest "$WORK_DIR/spike-patch"
check_manifest "$WORK_DIR/tests"
check_manifest "$WORK_DIR/docs"

echo "[verify_oracle] OK"
