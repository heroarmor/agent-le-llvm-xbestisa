# Setup — what's where, and how to get the agent runnable

> **TL;DR:** The 41 KB input archive is the **harness** (task spec, grader, tests, patches). The full **runtime environment is delivered as a 1.54 GB Docker image tarball** at the [v1.0-binaries Release](https://github.com/heroarmor/agent-le-llvm-xbestisa/releases/tag/v1.0-binaries). Three paths are documented below: **Docker image** (~3 min, recommended), **fast bootstrap** (~35 min, uses Release oracle binaries + builds LLVM), and **cold-from-source** (~45 min, builds everything from upstream pinned commits).
>
> **The agent does NOT need network access at runtime.** All artifacts (LLVM source, pre-built clang/llc/llvm-mc, patched Spike, pk, riscv-toolchain, harness) are baked into the Docker image. Network is only needed once — at image-pull time.

---

## What's in each layer

| Layer | Size | Where it lives | What it contains |
|---|---|---|---|
| **Input archive** (`agent-le-input.tar.gz`) | **38 KB** | This repo + form upload | TASK.md, docs/, tests/ corpus, grader/, patches in `spike-patch/`, examples/, scripts/, Dockerfile. **The harness.** |
| **Reference output** (`agent-le-output.tar.gz`) | **12 KB** | This repo + form upload | `solution.patch` (216 LOC), scorecard.json, BUILD_LOG.txt, E2E_LOG.txt, walkthrough.md. **The gold standard.** |
| **Pre-built oracle binaries** | **10 MB** | [GitHub Release v1.0-binaries](https://github.com/heroarmor/agent-le-llvm-xbestisa/releases/tag/v1.0-binaries) | `spike-xbestisa` (the patched Spike, the **correctness oracle**), `pk-rv64imac` (proxy kernel). Stripped binaries with verified SHA-256. |
| **Pre-built Docker image** | **1.54 GB** | [v1.0-binaries Release](https://github.com/heroarmor/agent-le-llvm-xbestisa/releases/download/v1.0-binaries/agent-le-xbestisa-1.0-image.tar.gz) | `agent-le-xbestisa-1.0-image.tar.gz` — full reproducible runtime: Ubuntu 24.04 + apt deps + LLVM source + pre-built clang/llc/llvm-mc + Spike + pk + harness. SHA-256: `baabd966471b7c326aab4c1b9b66e294cd60bf7f5e2373a484c9c04309b5ade6`. **Recommended starting point.** |
| **LLVM 18.1.3 source** | **~1.3 GB** | [github.com/llvm/llvm-project](https://github.com/llvm/llvm-project) tag `llvmorg-18.1.3` (commit `c13b7485b87909fcf739f62cfa382b55407433c0`) | Cloned by the Dockerfile / setup script. The agent's working tree. |
| **LLVM build/** | **~5 GB** | Built locally (cold ~30 min, warm ccache ~60 s incremental) | `clang`, `llc`, `llvm-mc`, etc. — what the agent rebuilds after editing `.td` files. |
| **Spike source** | **~30 MB** | [github.com/riscv-software-src/riscv-isa-sim](https://github.com/riscv-software-src/riscv-isa-sim) commit `0ad45926ac6f42d0d39e936abf4ab1cb9bdc5086` | Used to rebuild Spike from scratch if the prebuilt binary's SHA doesn't match for some reason. |
| **riscv-pk source** | **~5 MB** | [github.com/riscv-software-src/riscv-pk](https://github.com/riscv-software-src/riscv-pk) commit `9c61d29846d8521d9487a57739330f9682d5b542` | Same. |
| **riscv64-unknown-elf toolchain** | **~500 MB** | apt: `gcc-riscv64-unknown-elf`; or build from `riscv-gnu-toolchain` | newlib + libc + crt for cross-compilation. The Dockerfile installs via apt. |
| **llvm-test-suite** | **~25 MB** | [github.com/llvm/llvm-test-suite](https://github.com/llvm/llvm-test-suite) tag `llvmorg-18.1.3` | Used by Tier 4 only. |

**Total environment size: ~7 GB.** Most of it is built deterministically from public source pinned to exact commits — **no proprietary blobs**.

---

## Docker path — ~3 minutes (RECOMMENDED)

Pre-built environment with LLVM, Spike, pk, toolchain, and harness all
baked in. Verified end-to-end on 2026-05-02.

```bash
# 1. Download the image (1.54 GB, public, no auth)
wget https://github.com/heroarmor/agent-le-llvm-xbestisa/releases/download/v1.0-binaries/agent-le-xbestisa-1.0-image.tar.gz
sha256sum -c <(echo "baabd966471b7c326aab4c1b9b66e294cd60bf7f5e2373a484c9c04309b5ade6  agent-le-xbestisa-1.0-image.tar.gz")

# 2. Load into Docker (~30 sec)
docker load < agent-le-xbestisa-1.0-image.tar.gz

# 3. Run
docker run --rm -it agent-le-xbestisa:1.0
# inside the container:
#   /work/llvm-project/        pre-cloned + pre-built LLVM 18.1.3 source
#   /work/llvm-project/build/  pre-built clang/llc/llvm-mc/llvm-mc/llvm-objdump/FileCheck
#   /usr/local/bin/spike       patched Spike (oracle, READ-ONLY)
#   /usr/local/bin/pk          riscv-pk proxy kernel
#   /work/harness/             TASK.md, docs/, tests/, grader/, scripts/, etc.
```

Inside the container, the agent's iteration loop:
```bash
cd /work/harness
less TASK.md                                              # read the task
$EDITOR /work/llvm-project/llvm/lib/Target/RISCV/...     # edit
ninja -C /work/llvm-project/build clang llc llvm-mc      # ~60 s warm rebuild
bash grader/grade.sh                                      # score
```

**No network access needed at runtime.** The image bundles everything.

---

## Fast bootstrap path — ~35 minutes

Uses the prebuilt Spike + pk from GitHub Releases, plus a pre-cloned LLVM source tree.

```bash
# 1. Get the harness (what's in the form's input archive)
git clone https://github.com/heroarmor/agent-le-llvm-xbestisa.git
cd agent-le-llvm-xbestisa

# 2. Grab the prebuilt oracle binaries
mkdir -p prebuilt && cd prebuilt
wget -q https://github.com/heroarmor/agent-le-llvm-xbestisa/releases/download/v1.0-binaries/spike-xbestisa
wget -q https://github.com/heroarmor/agent-le-llvm-xbestisa/releases/download/v1.0-binaries/pk-rv64imac
wget -q https://github.com/heroarmor/agent-le-llvm-xbestisa/releases/download/v1.0-binaries/SHA256SUMS
sha256sum -c SHA256SUMS  # verify
chmod +x spike-xbestisa pk-rv64imac
cd ..

# 3. Get the LLVM source the agent will modify
git clone --depth 1 --branch llvmorg-18.1.3 https://github.com/llvm/llvm-project.git
cd llvm-project
[[ "$(git rev-parse HEAD)" == "c13b7485b87909fcf739f62cfa382b55407433c0" ]] || echo "WARN: SHA mismatch"

# 4. Build LLVM (one-time cold ~30 min on 16 vCPU; subsequent edits are 60 s incremental)
cmake -G Ninja -S llvm -B build \
  -DCMAKE_BUILD_TYPE=Release -DLLVM_TARGETS_TO_BUILD=RISCV \
  -DLLVM_ENABLE_PROJECTS="clang;lld" -DLLVM_PARALLEL_LINK_JOBS=2 \
  -DLLVM_USE_LINKER=lld -DLLVM_CCACHE_BUILD=ON -DLLVM_OPTIMIZED_TABLEGEN=ON
ninja -C build clang llc llvm-mc llvm-objdump FileCheck

# 5. Verify end-to-end with the reference solution
cd ..
git apply --directory=llvm-project reference-solution/solution.patch
ninja -C llvm-project/build clang llc llvm-mc llvm-objdump   # ~60 s warm rebuild
LLVM_SRC=$PWD/llvm-project SPIKE_SRC=/dev/null \
PK_BIN=$PWD/prebuilt/pk-rv64imac SPIKE_BIN=$PWD/prebuilt/spike-xbestisa \
RISCV_TOOLS=/usr  bash scripts/run_real_demo.sh   # use system riscv64 toolchain
```

Expected output: `[demo] ✓ outputs match byte-exactly` and `scorecard.json` showing `stdout_byte_exact: true`.

**Wall-clock breakdown (16 vCPU, 32 GB RAM):**
- Step 1 (clone harness): 5 sec
- Step 2 (download prebuilt): 30 sec
- Step 3 (clone LLVM): 90 sec
- Step 4 (cold LLVM build): **30 min** ← unavoidable unless we ship a Docker image with the build/ dir
- Step 5 (apply patch + rebuild + run): **2 min**

Total cold-start: **~35 min**. Subsequent agent iterations (edit .td, rebuild, retest): **~75 sec each**.

---

## Cold path (full build from scratch) — ~45 minutes

For evaluators who want a fully self-contained reproducible build with no GitHub Release dependency:

```bash
git clone https://github.com/heroarmor/agent-le-llvm-xbestisa.git
cd agent-le-llvm-xbestisa
bash scripts/setup_workspace.sh   # builds LLVM + Spike + pk from upstream pinned commits
```

This script:
1. `apt install` build dependencies.
2. Clones LLVM, Spike, riscv-pk at exact pinned SHAs.
3. Builds LLVM (~30 min).
4. Applies the Spike patch from `spike-patch/`, builds Spike (~3 min).
5. Builds pk (~2 min).
6. Verifies all SHAs match.

---

## Building the Docker image from scratch

If you want to verify the published image matches a fresh build from source:

```bash
docker build -t agent-le-xbestisa:1.0 -f docker/Dockerfile .   # ~45 min on 16 vCPU
```

The published image at the v1.0-binaries Release was built using this same
Dockerfile against pinned commit SHAs (LLVM `c13b7485b…`, Spike `0ad45926…`,
pk `9c61d298…`).

---

## What the agent actually starts with at task time

When this task is dispatched to an agent, the agent's working directory contains:
- All files from `agent-le-input.tar.gz` (the 38 KB harness).
- A pre-built `llvm-project/build/` (warm ccache, ~60 s incremental cycle) — provided by the Docker image / pre-warmed VM image.
- The patched Spike binary at `prebuilt/spike-xbestisa` (or `spike/install/bin/spike` in the Docker image) — the read-only oracle.
- The pk binary at `prebuilt/pk-rv64imac`.
- A `riscv64-unknown-elf` cross-toolchain (newlib).

**The agent does NOT have to do a cold LLVM build.** That cost is borne once when the Docker image / pre-warmed VM is built (or, for the fast path above, once by the evaluator).

The agent's iteration loop is:
1. Edit `llvm-project/llvm/lib/Target/RISCV/RISCVInstrInfoBestISA.td` (or other allowed files)
2. `ninja -C llvm-project/build clang llc llvm-mc` — **~60 s**
3. `bash grader/tier1_lit.sh` (or another tier) — seconds to minutes
4. Repeat

A focused agent can do 30+ iterations in the 24 h budget.

---

## Pinned versions reference

| Component | Pin |
|---|---|
| Ubuntu base | `ubuntu:24.04` (digest pinned in Dockerfile) |
| LLVM | tag `llvmorg-18.1.3` = commit `c13b7485b87909fcf739f62cfa382b55407433c0` |
| Spike (riscv-isa-sim) | commit `0ad45926ac6f42d0d39e936abf4ab1cb9bdc5086` |
| riscv-pk | commit `9c61d29846d8521d9487a57739330f9682d5b542` |
| llvm-test-suite | tag `llvmorg-18.1.3` |

All SHAs are recorded in `docker/Dockerfile` and `scripts/setup_workspace.sh`. Floating tags / `:latest` are NEVER used.
