# TODO — fill out the remaining 28 correctness programs

Programs `01_andn3_basic.c` and `14_clmulacc_basic.c` are provided as canonical templates. The remaining 28 programs (per the inventory in `README.md`) follow the same structure:

1. Conditionally include the builtin path under `#if defined(__riscv) && defined(__riscv_xbestisa)`, fall back to a pure-C reference for non-RISC-V hosts.
2. Run a small fixed table of inputs that covers the per-instruction edge cases listed in the README.
3. Compute a checksum (XOR-fold of all results) and print it via `printf("... = 0x%016llx\n", ...)`.
4. Print `OK yes` if builtin and reference match, `OK no` otherwise.

### Why this structure
- **Both paths exercised**: builtin path tests Tier 2 even if the agent's ISel is broken; the idiomatic-C path also exercises ISel implicitly (extra signal beyond Tier 3a's `grep` check).
- **No floating-point, no time, no PRNG, no env vars** → deterministic stdout.
- **Single `printf` per result + final OK line** → diff-friendly.
- **No dynamic allocation** → minimal `pk` syscall surface.

### Per-program checklist before commit
- [ ] Compiles with both `-march=rv64gc_xbestisa` and `-march=rv64gc`.
- [ ] Runs cleanly on `spike --isa=rv64gc_xbestisa pk` and on `spike --isa=rv64gc pk` (when the builtin guard is `#else`).
- [ ] Stdout is byte-identical between the two builds.
- [ ] `<prog>.expected_out` checked in for grader debugging (NOT trusted at grade time — grader recomputes the reference).
