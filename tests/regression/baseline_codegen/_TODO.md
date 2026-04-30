# `baseline_codegen/` — 50 standalone C compilation units for Tier 3b

The packaged release contains 50 short `.c` files. Each is compiled twice
(agent's clang vs. reference clang) at `-O2 -march=rv64gc -c` and the
opcode-mnemonic histograms must match.

## Sourcing plan
- 25 from llvm-test-suite SingleSource (Apache-2.0 with LLVM Exceptions).
- 15 from CompCert benchmark suite (BSD).
- 10 hand-written by the task author (Apache-2.0).

## Inventory targets
- 10 arithmetic-heavy (mul/div/mod chains)
- 10 control-flow-heavy (nested switches, loops, gotos)
- 10 memory-heavy (struct field ops, pointer chasing)
- 10 function-call-heavy (tail calls, argument passing edge cases)
- 10 mixed (real-world-shaped: small parser, hash function, sort, etc.)

## Why 50?
- Large enough to detect a wide range of accidental codegen perturbations.
- Small enough to compile both ways in <30 s total at `-O2 -c`.
- Each file ≤200 LOC keeps any opcode-histogram diff easy to triage.
