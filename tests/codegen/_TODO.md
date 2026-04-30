# TODO — fill out the remaining 6 codegen probes

Probes `01_andn3_simple.c`, `03_xor3_simple.c`, `06_maddw_simple.c`, and `08_sha256ch_simple.c` are provided as canonical templates.

The remaining 6 probes (per `README.md` inventory) follow the same one-function-per-file structure:

- `02_andn3_commuted.c` — `~b & ~c & a` (tests pattern-matcher commutativity)
- `04_xor3_assoc.c` — `a ^ (b ^ c)` (tests associativity-aware matching)
- `05_xor3_unrolled.c` — 8-way XOR fold; expect ≥4 `bestisa.xor3` after `-O2` instcombine
- `07_maddw_loop.c` — accumulator loop (tests that the matcher survives loop-invariant code motion)
- `09_sha256ch_round.c` — full one-round SHA-256 compression (tests xor3+sha256ch interaction)
- `10_mixed_three.c` — function using all three (andn3, xor3, maddw); count xor3 only
