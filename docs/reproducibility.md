# Reproducibility & Version Pins

## Component versions (frozen for benchmark v1.0)

| Component | Pin | Source |
|---|---|---|
| `llvm-project` | tag `llvmorg-22.1.0` (commit will be set when packaging) | https://github.com/llvm/llvm-project |
| `riscv-isa-sim` (Spike) | commit `<TBD-pin-at-package-time>` | https://github.com/riscv-software-src/riscv-isa-sim |
| `riscv-pk` (proxy kernel) | matching Spike tag | https://github.com/riscv-software-src/riscv-pk |
| `llvm-test-suite` | tag `llvmorg-22.1.0` | https://github.com/llvm/llvm-test-suite |
| Ubuntu base image | `ubuntu:24.04` | Docker Hub digest pinned |
| `XBestISA` ISA spec | v1.0 (this repo) | `docs/XBestISA_spec.md` |

All source pins are recorded in `docker/Dockerfile` as exact commit SHAs / image digests, never floating tags or `:latest`.

## Determinism guarantees

The grader (`grader/grade.sh`) is deterministic given:
1. The same agent submission (same `git diff` against `llvmorg-22.1.0`).
2. The same starting Docker image.
3. The same host CPU architecture (x86_64).

Two independent runs produce **bit-identical** `scorecard.json` (modulo `timestamp_utc`).

Sources of non-determinism that have been eliminated:
- **Parallelism in lit**: lit is run with `--order=lexical -j1` for grading runs (slower but deterministic test ordering and output).
- **Spike PRNG**: `pk` uses no PRNG. Spike instruction trace mode is disabled.
- **Compiler timestamps**: `__DATE__` / `__TIME__` are not used in any test program.
- **ccache**: cached objects do not affect generated code; only build wall time.

## Oracle integrity

The Spike binary is the **correctness oracle** for Tiers 2 and 4. Tampering = automatic Tier 0 failure.

Verification (run at the start of `grade.sh`):

```bash
EXPECTED_SHA=<pinned at package time>
ACTUAL_SHA=$(sha256sum spike/build/spike | cut -d' ' -f1)
[[ "$EXPECTED_SHA" == "$ACTUAL_SHA" ]] || {
    echo "FATAL: Spike oracle binary has been modified. Submission rejected." >&2
    exit 99
}
```

The hash is also recorded in `scorecard.json` as `oracle_sha256_ok: true|false`.

## Reference toolchain

`reference-toolchain/` in the Docker image is an **unmodified** build of `llvmorg-22.1.0` (no `XBestISA` patches). Used by:

- **Tier 2**: compile each test program a second time with `-march=rv64gc` (no extension) for the bit-exact stdout comparison.
- **Tier 3b**: opcode-histogram baseline for the no-regression check.
- **Tier 4**: baseline `llvm-test-suite` compile.

The reference toolchain is hashed and verified the same way as the Spike binary.

## Test corpus integrity

`scripts/verify_oracle.sh` also checks:
- SHA-256 of every file under `tests/` matches `tests/MANIFEST.sha256`.
- SHA-256 of every file under `docs/` matches `docs/MANIFEST.sha256`.
- SHA-256 of every file under `spike-patch/` matches `spike-patch/MANIFEST.sha256`.

If any test or oracle file has been tampered with, the grader exits 99 with a clear error. This is the second line of defense after the Spike binary check.

## What the agent IS allowed to modify

Anything under `llvm-project/` **except**:
- Files matching `llvm-project/**/test/**/RISCV/**` that are listed in `tests/regression/baseline_lit.txt` (these must keep passing as-is; the agent may add **new** test files alongside them).

The agent MAY:
- Add new files anywhere under `llvm-project/llvm/lib/Target/RISCV/`.
- Add new files under `llvm-project/llvm/test/CodeGen/RISCV/` and `llvm-project/llvm/test/MC/RISCV/`.
- Modify any existing `.td`, `.cpp`, `.h`, `.def` file under `llvm-project/llvm/lib/Target/RISCV/` and `llvm-project/clang/lib/CodeGen/`.
- Modify `llvm-project/clang/include/clang/Basic/BuiltinsRISCV.def`.
- Modify `llvm-project/llvm/include/llvm/IR/IntrinsicsRISCV.td`.
- Modify `llvm-project/llvm/lib/TargetParser/RISCVISAInfo.cpp` and `llvm-project/llvm/include/llvm/TargetParser/RISCVTargetParser.def`.
- Modify `llvm-project/llvm/unittests/TargetParser/RISCVISAInfoTest.cpp`.
- Modify `llvm-project/llvm/docs/RISCVUsage.rst` and `llvm-project/llvm/docs/ReleaseNotes.md`.

The agent MUST NOT modify:
- Anything under `spike/`, `spike-patch/`, `llvm-test-suite/`, `tests/`, `docs/`, `examples/`, `reference-toolchain/`, `grader/`, or `scripts/`.

`grader/grade.sh` enforces this with a `git diff --stat` check at the top: any change outside the allowed paths causes Tier 0 = 0.
