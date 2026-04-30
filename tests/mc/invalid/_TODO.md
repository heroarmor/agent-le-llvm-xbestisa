# TODO — 8 more invalid MC tests

`wrong_arity_andn3.s` and `typo_mnemonic.s` are provided as canonical templates.
Add the remaining 8 per the inventory in `../README.md`.

Each is a 1-line `.s` file plus a `.expected_err` containing a substring of the
diagnostic that `llvm-mc -triple=riscv64 -mattr=+xbestisa <file>` should emit
to stderr.

Use `grep -F` semantics — substring match, no regex.
