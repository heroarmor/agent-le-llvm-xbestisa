# Agent-LE Task: LLVM Backend Extension for a Custom RISC-V ISA (`XBestISA`)

> **Task short name:** `llvm_riscv_custom_ext_instance_1`
> **Industry domain:** Compiler Engineering / Computer Architecture
> **Software:** LLVM 18.1.3, Clang 18, riscv-isa-sim (Spike), llvm-test-suite
> **OS:** Linux (Ubuntu 24.04, x86_64 host with riscv64-unknown-elf cross toolchain)
> **Licensing:** Free / Open Source (Apache 2.0 with LLVM Exceptions, BSD)
> **Estimated expert time:** 1.5–2 days (experienced LLVM backend engineer; see `reference-solution/walkthrough.md` §5)
> **Agent wall-clock budget:** 24 hours
> **Reference solution status:** ✅ **Real & verified end-to-end as of 2026-05-01** — see `reference-solution/E2E_LOG.txt` for the actual build + Spike-execution proof.
>
> **Runtime environment:** prebuilt oracle binaries (Spike + pk, 10 MB total, SHA-pinned) are at the [v1.0-binaries Release](https://github.com/heroarmor/agent-le-llvm-xbestisa/releases/tag/v1.0-binaries). Full setup, including what's in the 38 KB input archive vs what's fetched at runtime, is documented in [`SETUP.md`](SETUP.md).

## What this task asks

Add **complete LLVM backend support** for a 7-instruction RISC-V vendor extension named `XBestISA` so that:

1. `clang -march=rv64gc_xbestisa` compiles natural C source and emits the new instructions via instruction selection.
2. The new instructions assemble, disassemble, and round-trip bit-exactly through the MC layer.
3. Compiled binaries execute **bit-exactly on the provided Spike simulator** vs. a scalar reference C implementation.
4. **No regression** in any pre-existing LLVM RISC-V test.

The agent must touch every layer of the compiler — Clang frontend builtins, LLVM IR intrinsics, TableGen subtarget feature, instruction definitions, ISel patterns, scheduling itinerary, and MC-layer assembler/disassembler — across an estimated **600–1,200 LOC of source plus 800–2,000 LOC of tests** in ~14 files.

This task structurally matches the **40+ vendor extensions merged into LLVM mainline since 2023** (T-Head, SiFive, Andes, OpenHW CORE-V, Ventana, Qualcomm, MIPS, SpacemiT, Rivos). Real-world reference: [Andes `XAndesVPackFPH` PR #138827](https://github.com/llvm/llvm-project/pull/138827) — same shape, smaller scope.

## Repo layout

```
.
├── TASK.md                       # full task description (read first)
├── docs/
│   ├── XBestISA_spec.md          # the 6-instruction ISA spec — the agent's only requirements doc
│   ├── grading_rubric.md         # 4-tier deterministic rubric (100 pts total)
│   ├── environment.md            # build env, hardware reqs, Docker
│   └── reproducibility.md        # version pins, oracle integrity
├── grader/
│   ├── grade.sh                  # main entry; runs all 4 tiers, emits scorecard.json
│   ├── tier{0..4}_*.sh           # per-tier graders
│   └── score.py                  # scorecard aggregator
├── tests/
│   ├── correctness/              # 30 .c programs + .expected_out (Tier 2 oracle comparison)
│   ├── codegen/                  # 10 .c snippets + .expected_count (Tier 3a)
│   │   └── llcheck/              # FileCheck patterns
│   ├── mc/{valid,invalid}/       # 20 .s files + .expected/.expected_err (Tier 1)
│   └── regression/               # baseline_lit.txt + baseline_codegen/ (no-regression)
├── spike-patch/                  # oracle: Spike patch implementing XBestISA semantics
├── examples/                     # READ-ONLY pointers to upstream XTHead/XSf/XAndes for reference
├── reference-solution/           # expert solution.patch + scorecard.json (gold standard)
├── docker/                       # reproducible build environment
└── scripts/                      # workspace setup, oracle integrity check
```

## Quick start (for the agent)

```bash
# 1. Build environment is pre-warmed by docker/Dockerfile (~12 GB image, ccache populated)
cd /work/llvm-project
ninja -C build clang llc llvm-mc llvm-tblgen   # ~60 s warm incremental

# 2. Read the spec
less /work/docs/XBestISA_spec.md

# 3. Look at upstream exemplars (read-only)
ls /work/examples/      # XTHead, XSf, XAndes

# 4. Iterate: edit .td/.cpp -> rebuild -> run grader
bash /work/grader/grade.sh   # prints scorecard.json
```

## Verification (high level)

| Tier | What | Points | Gate |
|---|---|---|---|
| 0 | Build green | 5 | `ninja` exits 0 |
| 1 | `llvm-lit` regression + new MC + new CodeGen `CHECK:` lines | 30 | byte-exact encoding hex, FileCheck pass |
| 2 | 30 hand-written C programs run **bit-exactly** on Spike vs. scalar reference | 35 | `diff` on stdout/stderr |
| 3 | Instruction selection on natural C + no opcode-set regression on 50 baselines | 20 | `grep` mnemonic count + opcode-set diff |
| 4 | `llvm-test-suite` SingleSource subset bit-exact on Spike vs. baseline `-march=rv64gc` | 10 | byte-exact stdout |
|   | **Pass = 80 / 100 · Strong pass = 95 / 100** | **100** | |

Full rubric: [`docs/grading_rubric.md`](docs/grading_rubric.md).

## Why this is a defensible Agent-LE task

- **Days, not minutes** — anchored to real merged PRs (`XAndesVDot` 105 LOC across 10 files; `XTHeadMac` ~700 LOC; Hexagon V75 ~1,500 LOC). The proposed scope sits squarely between them.
- **Professional-grade tooling** — production LLVM, production Spike, production llvm-test-suite. Same toolchain every silicon vendor uses.
- **Verifiable** — every tier is deterministic. Two runs of `grade.sh` on the same submission produce identical scores. No subjective rubric items.
- **Uncovered niche** — `llvm-bench` / `llvm-autofix` (arXiv:2603.20075) cover middle-end LLVM bugs; SWE-bench has only Clang frontend issues. No existing benchmark covers backend extension work.
- **Hard for current agents** — TableGen DSL idiosyncrasies + multi-pass codegen + 60 s build cycles + the "tests pass but instruction not selected" silent-failure trap. Frontier models drop ~62% in pass rate from SWE-bench Verified to compiler-bug benchmarks.

## Reproducing the verified end-to-end run

```bash
# Apply patches to clean source trees
git -C llvm-project checkout llvmorg-18.1.3
git -C llvm-project apply ../reference-solution/solution.patch

git -C riscv-isa-sim apply ../spike-patch/0001-add-xbestisa-extension.patch

# Build (incremental on warm caches: LLVM ~60s, Spike ~3min)
ninja -C llvm-project/build clang llc llvm-mc llvm-objdump
( cd riscv-isa-sim/build && ./config.status && make -j$(nproc) spike )

# Run the e2e demo (compiles a 3-function C program, runs both
# xbestisa and baseline builds on Spike, byte-exact diffs stdout)
LLVM_SRC=$PWD/llvm-project SPIKE_SRC=$PWD/riscv-isa-sim \
PK_BIN=$PWD/riscv-pk/build/pk RISCV_TOOLS=$PWD/riscv-toolchain \
bash scripts/run_real_demo.sh
```

Expected: `[demo] ✓ outputs match byte-exactly` and `scorecard.json` showing `stdout_byte_exact: true`. See `reference-solution/E2E_LOG.txt` for the captured 2026-05-01 run.

## License

Apache-2.0 with LLVM Exceptions (matching the LLVM project itself).
