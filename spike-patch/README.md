# `spike-patch/` — Spike (riscv-isa-sim) oracle patch

Adds `XBestISA` semantics to Spike. **The agent must NOT modify any file in this directory or the resulting Spike binary.** A SHA-256 of the built binary is verified at the start of every `grade.sh` run.

## What this patch adds

- `riscv/insns/bestisa_andn3.h`     — semantics for instruction 1
- `riscv/insns/bestisa_xor3.h`      — semantics for instruction 2
- `riscv/insns/bestisa_maddw.h`     — semantics for instruction 3
- `riscv/insns/bestisa_sha256ch.h`  — semantics for instruction 4
- `riscv/insns/bestisa_clmulacc.h`  — semantics for instruction 5
- `riscv/insns/bestisa_bfly.h`      — semantics for instruction 6
- `riscv/encoding.h`                — opcode masks and match patterns
- `riscv/riscv.mk.in`               — adds the new insn files to the build
- `disasm/disasm.cc`                — disassembler entries for nice trace output
- `riscv/processor.cc`              — registers the `xbestisa` extension string

## Files

- `0001-add-xbestisa-extension.patch` — the consolidated patch file (apply with `git am` or `patch -p1` against a clean Spike checkout at the pinned commit).
- `apply.sh` — convenience wrapper:
  ```bash
  bash spike-patch/apply.sh /path/to/clean/riscv-isa-sim
  ```
- `MANIFEST.sha256` — SHA-256 of every file in this directory (used by `scripts/verify_oracle.sh`).
- `built-binary.sha256` — SHA-256 of the resulting `spike` binary after `./configure && make`. The grader checks this against the running binary.

## Spike commit pin

`<TBD-pin-at-package-time>` — the exact upstream `riscv-software-src/riscv-isa-sim` commit the patch is rebased against. Recorded in `apply.sh`.

## Build

```bash
cd /tmp
git clone https://github.com/riscv-software-src/riscv-isa-sim.git
cd riscv-isa-sim
git checkout <TBD-pin>
patch -p1 < /work/spike-patch/0001-add-xbestisa-extension.patch
mkdir build && cd build
../configure --prefix=$PWD/../install --with-isa=rv64gc_xbestisa
make -j$(nproc) install
```

The pre-built binary at `/work/spike/install/bin/spike` in the Docker image is the canonical oracle and matches `built-binary.sha256`.

## Why Spike (not QEMU or gem5)

- **Spike** is the official RISC-V reference simulator. Adding a new instruction is a 30-line change to one header (`riscv/insns/<op>.h`) plus one entry in `riscv/encoding.h`.
- **QEMU** TCG would require writing a TCG translator helper — much more complex.
- **gem5** would require microarchitectural pipeline modeling — out of scope.
- **Verilator + Rocket** would require building the actual hardware — orders of magnitude slower per test.

For a correctness oracle (which is all we need for Tiers 2 and 4), Spike is the right tool.
