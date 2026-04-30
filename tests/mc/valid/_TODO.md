# TODO — 9 more valid MC tests + their `.expected` files

`andn3.s` is the canonical template.

Add the remaining 9 per the inventory in `../README.md`. Each is a 1–10-line
`.s` file plus a matching `.expected` containing the byte-exact stdout of:
```
llvm-mc -triple=riscv64 -mattr=+xbestisa -show-encoding <name>.s
```
including the leading `.text`, the `# encoding: [...]` byte hex, and trailing
newline. The grader regenerates this from the gold-standard solution at grade
time; bundled `.expected` files are for offline development and may be slightly
stale.
