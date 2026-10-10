# 2026-10-09 — Finish pass: grammar repaired, plugin wired, license normalized

Facts established during the completion pass (all verified on primo):

- This repo is a tree-sitter grammar for Mojo plus a Neovim plugin — not a
  TypeScript plugin. The only TypeScript is `bindings/node/index.d.ts`.
- `src/scanner.c` was a stub whose token enum never matched the grammar's
  externals; it has been rewritten from tree-sitter-python's scanner logic
  (MIT, attributed in the file) with this grammar's token order. Any future
  scanner edit must keep the enum order identical to the `externals` list in
  `src/grammar.js`.
- Grammar fixes landed: effect specifiers (`raises` etc.) are independent of
  the return-type group; `let` is a declaration prefix; bare `ref` is an
  argument convention alongside `ref[origin]`.
- Corpus suite: `test/corpus` (24 cases, incl. two malformed-input cases).
  `tree-sitter test` is the grammar gate.
- `vim.treesitter.query.get` takes `(lang, name)` — two call sites had the
  arguments swapped and silently never loaded queries.
- nvim-treesitter's rewritten API has no `get_parser_configs()`; the Lua
  registration paths guard for its absence and report false instead of
  throwing. The legacy (master) API path is verified end to end.
- The Rust binding's `build.rs` must live at the package root for cargo to
  run it (it was misplaced in `bindings/rust/`).
- The stock Python `setup.py` was unimportable (`ext_package` with a dotted,
  dashed name); it was replaced with a minimal working one.
- License is Apache-2.0 only (normalized 2026-10-09, following the
  2026-09-28 org decision recorded in decisions.md). LICENSE-AGPL and
  LICENSE-QCDA are removed.
- Bindings verified on primo: Rust, Go, Python, Zig, C (make/CMake), Node
  typings (tsc strict). Swift is unverified — no Swift toolchain on primo.
- Nix: `flake.nix` provides `packages.default` (parser + queries),
  `packages.nvim-plugin`, corpus/query checks, and a devShell;
  `nix flake check` passes on x86_64-linux.
