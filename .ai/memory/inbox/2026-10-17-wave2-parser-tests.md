# Wave 2: compiler parser-test census — fix phase (2026-10-17)

Sandbox-only work on top of 4753694 (the shipped-code census commit);
16 local commits, 2e2b70a..228f441. Nothing pushed. Pax reviews the
gates before any landing. Census records live outside the repo at
~/workspace/blaze-ts-update/wave2/ (TRIAGE.md, census_final2.txt,
negcheck.py, negcheck_out.txt).

## Result

Tree: modular/modular Mojo/test/mojo-parser, 523 files.
Baseline (4753694 grammar): 83 failing / 910 ERROR / 9 MISSING.
Final: 35 failing / 230 ERROR / 2 MISSING. Every remaining failure is
a negative test (expected-error markers or RUN: not %parse), except
two pinned residuals below. Of the 39 POSITIVE-classified files, 36
parse clean; one (decls/imm_convention_fixit.mojo) is a RUN: not
%parse negative misclassified by the marker rule.

Gates at HEAD: corpus 92/92 (73 baseline + 19 Wave 2 pins, all in
test/corpus/wave2.txt with eyeball-verified trees), adversarial
17/17, shipped census unchanged at 4 files / 8 ERROR / 0 MISSING
(the documented bracket-segment residual), estate census 0/0, doc
sweep 1098/1136 (was 1096 at 4753694; family 6 recovered two).

## Pinned residuals (compiler-accepted, grammar rejects)

1. closures/unified_closure_traits.mojo (2E, one line):
   `comptime s11_RowBody = ImplicitlyCopyable & RegisterPassable &
   def(Int) -> None`. Admitting intersection_type as a comptime value
   parses the line but re-shapes 5 eyeball-verified corpus pins (the
   intersection reading steals pinned comptime values) — the same
   toxicity the shipped-code census recorded. Reverted in family 14.
2. ownership/ownership.mojo (2E, one site): an MLIR bracket-call
   continuation on the following line at deeper indent,
   `__mlir_op.`kgen.rebind`` then `[_type=...](litref)`. This is
   scanner territory (indented continuation outside brackets); the
   single-line form parses. No grammar-only cure attempted.

## Corrections and falsified cures found this phase

- Family 8's report claimed exprs_misc.mojo at 0E; rebuilding that
  grammar shows `ref r5: Int` failing there too (the probe ran
  against a stale parser). Fixed for real in family 15 (38a365b).
- Removing generator_type_application from the type fork (family 12
  first attempt) culled bracket-entry expression stacks in shipped
  code (block_scaled_matmul*.mojo) — shipped census 4/8/0 -> 6/12/0.
  Both rules now coexist. Same segment-cull law as the residual.
- Widening the shared conformance_clause trait field to admit
  intersection_type (family 10 first attempt) culled call-argument
  stacks estate-wide (estate 0 -> 209E, doc sweep 1098 -> 1062).
  The cure was dedicated negative/intersection clause rules wired
  only into superclass_list and trait_list.
- Duplicating the fn-type thin/abi segment after the effects made
  generate run past 10 minutes (family 13); thin as an
  _fn_type_effect token plus a declared [function_type,
  _fn_type_effect] conflict does the same job in normal time.
- Generate time roughly doubled at family 6 (backtick names in type
  positions) to ~4 min; parser.c is ~55 MB. All gates hold, but the
  cost is worth weighing at landing review.

## Negative-file spot-check

wave2/negcheck.py compares our ERROR line ranges against each
negative file's expected-error marker lines. Verdict: coincidence
holds under the @+1/@below comment conventions; four files produce
one wide ERROR region covering their marked lines (recovery quality,
not over-strictness). The check surfaced four valid-with-warning
constructs the grammar rejected, all fixed in family 16 (228f441):
plain `async` fn types, tuple-pattern walrus targets, the
register_passable effect, stacked var/ref case patterns.

## Landing note

The parser binaries (parser/mojo.so, parser/mojo.wasm) were NOT
rebuilt during this phase; the family commits carry grammar.js,
grammar.json, node-types.json, parser.c, and corpus only. Rebuild
the binaries from parser.c at landing time, as was done for
4753694.
