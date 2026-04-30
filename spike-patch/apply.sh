#!/usr/bin/env bash
# apply.sh — apply the XBestISA patch onto a clean riscv-isa-sim checkout.
set -euo pipefail

SPIKE_PIN="<TBD-pin-at-package-time>"

if [[ $# -ne 1 ]]; then
    echo "usage: $0 <path-to-clean-riscv-isa-sim>" >&2
    exit 2
fi

SPIKE_DIR="$1"
PATCH_DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$SPIKE_DIR"
HEAD_SHA="$(git rev-parse HEAD)"
if [[ "$HEAD_SHA" != "$SPIKE_PIN" ]]; then
    echo "WARNING: spike checkout is at $HEAD_SHA, expected $SPIKE_PIN" >&2
    echo "         continuing anyway, but oracle hash will not match." >&2
fi

patch -p1 < "$PATCH_DIR/0001-add-xbestisa-extension.patch"

echo "Patch applied. Now: mkdir build && cd build && ../configure ... && make"
