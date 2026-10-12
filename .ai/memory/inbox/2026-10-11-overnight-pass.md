# 2026-10-11 — Overnight campaign pass: node_modules untracked, queries verified, SCIP indexed

Facts established during the overnight completion pass (all verified on primo):

- Corpus gate green: `npm test` (`tree-sitter test`) passes 24/24 corpus
  cases, 100% parse success, before and after this pass's changes.
- The four editor queries in `runtime/queries/mojo/` (highlights, folds,
  indents, locals) are complete, not stubs — the stub state in the
  2026-10-05 survey was closed by the 2026-10-09 finish pass. All four
  were re-validated this pass with `tree-sitter query` against a sample
  Mojo file exercising structs, fn, for/if, try/except: every query
  compiles against `src/node-types.json` and produces captures.
- `node_modules/` was still tracked (20 files: node-gyp-build and
  tree-sitter-cli packages) despite `/.node_modules/` already being in
  `.gitignore`. Untracked with `git rm -r --cached`; files remain on disk
  locally. `.gitignore` duplicate lines deduplicated in the same pass.
- SCIP: `scip-lua --corpus . --out-dir .` indexes the Lua plugin sources
  (8 files, 380 definitions, 849 occurrences, 288 unresolved — mostly
  Neovim API surface). Generated `index.scip` is a local artifact and is
  now gitignored; regenerate with the same command, do not commit it.
- `current.md` previously carried a language-mirror template that did not
  describe this repo; refreshed this pass.
