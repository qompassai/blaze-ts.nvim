# Shipped-code census program — grammar grown from Modular's official repos

Date: 2026-10-16. Commission: Matt, after the Mojo 1.1.0 update
(iterations 1–14) and iteration 14 (typed self parameters, a74f4f6).
Method: census the *shipped* code of `modular/modular` (sparse blobless
clone, HEAD efb7c37, 2026-10-15) — `Mojo/stdlib/std` +
`max/kernels/src` + `max/mojo` = 962 `.mojo` files. Every failure there
is definitionally a grammar bug; the estate and the 1.1.0 doc sweep are
regression gates, not growth sources.

## Trajectory (failing files / ERROR / MISSING of 962)

- Baseline (a74f4f6 grammar): 496 / 10,989 / 19
- Waves A–D (signatures, patterns, declarations, MLIR/values): 149 / 1,797 / 13
- Type-system root cure + fn-type cures: 46 / 173 / 8 (census_p)
- Final: **4 / 8 / 0** (census_t)

Final gates: corpus 73/73 (22 new pins in `test/corpus/census.txt`),
adversarial 17/17, doc sweep 1,096/1,136, estate census 0/0,
`tree-sitter generate` warning-clean.

## The residual (documented, bounded)

Four files, eight errors, one family: inside generic brackets, an entry
that is a binary expression whose LHS segment completes a *type*
reading through brackets or a call culls the expression stack —
`IndexList[type_of(x).rank + 1]`, `SIMD[size_of[T]() * 2]`,
`type_of(a).rank + Indices[0].rank - 1`. Files:
`Mojo/stdlib/std/format/_utils.mojo`,
`max/kernels/src/graph_compiler/builtin_kernels/{conv,gather_scatter,kernels}.mojo`.
Identifier/member-headed segments are fine; value position is fine
(there the brackets are a subscript). Three cure attempts
(dynamic-precedence boosts, conflict declarations, an entry-specific
type fork) all failed or regressed the estate — the entry fork must
remain exactly `$.type`; do not retry the `_entry_type` split.

## Lessons that cost real time (do not relearn)

- `generic_type_expression`'s identifier-headed call branch
  (`type_of(x)` form) culls call expressions in bracket entries.
  Cure: gte's call branch is member-headed only; `type_of` is its own
  rule (`type_call`, literal token) aliased into `$.type` and
  `_return_type` as `generic_type_expression`.
- The hand-rolled `_comptime_type` fork shredded member-generic
  annotations (`A.b[k=v]`) into ERROR-free fragments — a silent
  misparse, worse than an error. It now delegates to `$.type`.
- Adding `intersection_type`/`union_type` (or a trait-composition
  rule) to the comptime *value* choices poisons unrelated comptime
  declarations. The working cure for `A & (def(...) -> T)` values was
  `parenthesized_function_type` in `primary_expression`.
- `var_pattern` belongs in `pattern_list` only (prec(-1)), never in
  `$.pattern`: in `$.pattern` it hijacks plain `var x = ...`.
- A bare `comptime X` (no annotation, no value) must stay an error:
  the declaration tail is a choice between a definition and an
  annotated associated-type requirement.

## Notable forms now covered

Empty brackets (`Tuple[]`, `def f[]()`), class-level and chained
`where` clauses, `where`/`conformance` else-messages (bare,
concatenated, parenthesized), brace literals with bare entries,
`__await`, `ref` call arguments, `ref`/`var` destructuring elements,
conditional types, supertrait member/generic types and conformance
clauses, dotted bracketed fn-type entries (`A.B[i].C`), nested and
MLIR fn-type entries, MLIR dimensioned types (`vector<4 x bf16>`),
double `where`, generic member-call chains in type position.

Note: `.ai/memory/current.md` remains stale (flagged in the previous
inbox note as well).
