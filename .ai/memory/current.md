# Current Work

blaze-ts.nvim — a tree-sitter grammar for the Mojo language
(`tree-sitter-mojo`) plus its Neovim plugin. Original Qompass AI project,
not a mirror of an upstream repo.

## Status

- Grammar gate: `npm test` (`tree-sitter test`) — 24/24 corpus cases pass.
- Editor queries in `runtime/queries/mojo/` (highlights, folds, indents,
  locals) are complete and validated against `src/node-types.json`.
- Bindings (Rust, Go, Python, Node, Zig, C) verified 2026-10-09; Swift
  unverified (no Swift toolchain on primo).
- `node_modules/` is untracked and ignored; `index.scip` is a generated,
  gitignored artifact (regen: `scip-lua --corpus . --out-dir .`).

## Standing rules

- License: Apache-2.0 (SPDX). `LICENSE` file byte-identical to canonical
  text except filled copyright line.
- Code changes are pushed only under Matt's explicit direction
  (the 2026-10-11 overnight campaign authorization covered this pass).
