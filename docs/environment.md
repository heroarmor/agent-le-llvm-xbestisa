# Build Environment

## Hardware requirements

| Resource | Recommended | Minimum |
|---|---|---|
| vCPU | 16 | 8 |
| RAM | 32 GB | 24 GB |
| Disk | 80 GB free | 50 GB free |
| GPU | none | none |

LLVM's official CMake docs recommend ≥ 15 GB RAM per parallel link job. With `-DLLVM_PARALLEL_LINK_JOBS=2`, 32 GB is comfortable; 24 GB works if other RAM use is minimal.

## OS

- **Ubuntu 24.04 LTS, x86_64** (the only officially supported configuration for this benchmark).
- Other Linux distros may work but are unsupported.
- macOS / Windows: not supported (Spike build issues + cross-toolchain availability).

## Toolchain

| Tool | Version | Notes |
|---|---|---|
| `cmake` | ≥ 3.20 | apt: `cmake` |
| `ninja-build` | any recent | apt: `ninja-build` |
| `clang` (host) | ≥ 16 | apt: `clang` (used to bootstrap LLVM build) |
| `lld` (host) | ≥ 16 | apt: `lld` (faster link than `ld.bfd`) |
| `ccache` | 4.x | apt: `ccache`; pre-populated 30 GB cache shipped in Docker image |
| `python3` | ≥ 3.10 | apt: `python3` (for grader, lit) |
| `riscv64-linux-gnu-*` | apt | apt: `gcc-riscv64-linux-gnu` (only used by `pk` / Spike sysroot) |

## LLVM build configuration

```bash
cmake -G Ninja -S llvm-project/llvm -B llvm-project/build \
  -DCMAKE_BUILD_TYPE=Release \
  -DLLVM_TARGETS_TO_BUILD=RISCV \
  -DLLVM_ENABLE_PROJECTS="clang;lld" \
  -DLLVM_PARALLEL_LINK_JOBS=2 \
  -DLLVM_USE_LINKER=lld \
  -DLLVM_CCACHE_BUILD=ON \
  -DLLVM_INCLUDE_TESTS=ON \
  -DLLVM_BUILD_TESTS=ON \
  -DLLVM_INSTALL_UTILS=ON \
  -DLLVM_OPTIMIZED_TABLEGEN=ON
```

| Setting | Why |
|---|---|
| `LLVM_TARGETS_TO_BUILD=RISCV` | Skip x86/ARM/etc. — saves ~10 min build time |
| `LLVM_ENABLE_PROJECTS="clang;lld"` | Need clang for builtins; lld speeds up host link |
| `LLVM_PARALLEL_LINK_JOBS=2` | Caps RAM use to ~30 GB peak |
| `LLVM_CCACHE_BUILD=ON` | Cuts incremental build to ~60 s |
| `LLVM_OPTIMIZED_TABLEGEN=ON` | TableGen runs hot during `.td` iteration |

## Build times (16 vCPU, 32 GB RAM, warm ccache)

| Operation | Wall-clock |
|---|---|
| Cold full build (empty ccache) | ~30 min |
| Warm full rebuild (no source changes) | ~5 min |
| **Incremental: edit one `.td`, rebuild RISCV target + clang** | **45–90 s** |
| `llvm-lit -v test/CodeGen/RISCV/` (~1.2 k tests) | 2–5 min |
| `llvm-lit -v test/MC/RISCV/` (~400 tests) | < 1 min |
| Spike build | ~5 min |
| `llvm-test-suite` SingleSource subset compile + run | 20–30 min |

The 60-second incremental cycle is the **inner loop** the agent will iterate on.

## Spike (riscv-isa-sim) build

```bash
cd spike
./configure --prefix=$PWD/install
make -j$(nproc)
make install
```

Pre-applied patch in `spike-patch/` adds `XBestISA` semantics to `riscv/insns/bestisa_*.h` and `riscv/encoding.h`. **The agent must NOT modify this binary.** A SHA-256 of the built `spike` binary is verified at grader startup (`scripts/verify_oracle.sh`).

## Cross-compilation sysroot

For `clang --target=riscv64-unknown-elf`:
- Newlib + `pk` (proxy kernel) bundled with Spike provide a minimal libc + syscall shim.
- Tests in `tests/correctness/` use only `<stdio.h>` (printf, puts) + `<stdint.h>` to keep the syscall surface minimal.

## Docker image

See `docker/Dockerfile`. Pre-built image: ~12 GB compressed, ~25 GB uncompressed. Contains:
- pinned `llvm-project` source @ `llvmorg-22.1.0`
- pre-built `build/` directory + warm ccache (~30 GB ccache pre-populated)
- pre-built Spike binary with `XBestISA` semantics
- `llvm-test-suite` checkout
- `reference-toolchain/` — unmodified upstream `llvmorg-22.1.0` build for Tier 2 / Tier 3b reference
- All apt dependencies installed

```bash
# Build (one-time, ~45 min)
docker build -t agent-le-xbestisa:1.0 -f docker/Dockerfile .

# Run grader
docker run --rm -v $PWD:/work agent-le-xbestisa:1.0 bash /work/grader/grade.sh
```

## Token / compute budget for the agent

| Resource | Budget |
|---|---|
| Wall-clock | 24 hours |
| LLVM rebuilds | ~16–24 cycles (1 full + 15–23 incremental) ≈ 60 min total build time |
| Token budget | 3 M tokens (room for: full read of `RISCVInstrInfoXTHead.td` + `XSf.td` exemplars; skim of `RISCVISelLowering.cpp`; multiple iteration rounds with logs in context) |
