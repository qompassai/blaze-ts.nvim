# blaze-ts.nvim

<a href="./LICENSE"><img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" alt="License: Apache 2.0"></a>

A tree-sitter grammar for the [Mojo](https://docs.modular.com/mojo/) programming language, packaged as a Neovim plugin.

The grammar is adapted from tree-sitter-python's architecture (Mojo's syntax is a Python superset) and extended with Mojo's own constructs: `fn`/`struct`/`trait` declarations, `var`/`let`/`alias`, effect specifiers (`raises`), argument conventions (`inout`, `owned`, `borrowed`, `out`, `read`, `mut`, `ref`), parametric declarations, and f-string interpolation. The external scanner is a full indentation/string scanner, and the grammar is covered by a tree-sitter corpus suite (`test/corpus`, 24 cases including malformed-input cases).

The Neovim plugin ships a prebuilt parser (`parser/mojo.so`, plus a WebAssembly build at `parser/mojo.wasm`), the tree-sitter queries (`runtime/queries/mojo/`), and opt-in editor integrations. nvim-treesitter is **not** required: the bundled parser registers with Neovim's built-in tree-sitter support. When nvim-treesitter is present, the plugin also registers a parser config so `:TSInstall mojo` builds the parser from this repository's C sources.

<details>
<summary>Installation</summary>

### lazy.nvim

```lua
{
  "qompassai/blaze-ts.nvim",
  ft = { "mojo", "🔥" },
  config = function()
    require("blaze-ts").setup({})
  end,
}
```

This repository's root `lazy.lua` is a ready-made spec with keymaps for the health commands.

### Manual

Clone the repository anywhere on your `runtimepath`, then:

```lua
require("blaze-ts").setup({})
```

`setup()` registers the `.mojo` (and `.🔥`) filetype, adds the plugin's `runtime/` directory so the queries resolve, registers the bundled parser, and — when nvim-treesitter's parser registry is available — registers the `mojo` parser config.

### Nix

```console
nix build .#nvim-plugin   # the plugin as a Vim plugin package
nix build                 # just the parser (parser/mojo.so) and queries
nix develop               # dev shell with every toolchain used below
```

Both packages and the corpus/query checks are exercised by `nix flake check`.

</details>

<details>
<summary>Commands and configuration</summary>

| Command                 | Action                                                                 |
| ----------------------- | ---------------------------------------------------------------------- |
| `:BlazeTS`              | Run `require("blaze-ts").setup()`                                       |
| `:BlazeHealth`          | Full health report (parser, queries, Mojo environment probe)            |
| `:BlazeParserHealth`    | Parser-only health (config registration, parser path, loadability)      |
| `:BlazeReinstallParser` | Reinstall via nvim-treesitter when available, else re-register the bundled parser |

The same functions are available from Lua: `require("blaze-ts").setup(opts)`, `.health_check()`, `.parser_health()`, `.reinstall_parser()`.

`setup()` is intentionally thin. The opinionated editor stack lives in `blaze-ts.config` and is applied only when `setup()` receives one of its section tables:

```lua
require("blaze-ts").setup({
  ts = {},          -- nvim-treesitter setup + parser registration
  conform = {},      -- conform.nvim formatter definition (mojo format)
  lsp = {},          -- mojo-lsp-server wiring (requires the binary on PATH)
  completion = {},   -- omnifunc on Mojo buffers
  diagnostics = {},  -- vim.diagnostic configuration
  keymaps = {},      -- buffer-local keymaps on Mojo buffers
  filetype = {},     -- filetype and buffer options
})
```

Each integration degrades gracefully when its companion plugin or binary is absent.

</details>

<details>
<summary>Development</summary>

Regenerate the parser after editing `src/grammar.js`:

```console
tree-sitter generate src/grammar.js
tree-sitter build -o parser/mojo.so
tree-sitter build --wasm -o parser/mojo.wasm .
```

Validate:

```console
tree-sitter test                 # corpus suite (24 cases)
npx eslint src/grammar.js        # grammar lint (eslint-config-treesitter)
make                             # build build/mojo.so via the Makefile
cmake -B build && cmake --build build
```

The scanner (`src/scanner.c`) implements indentation, newline, and string tokens with fixed-size state (indent stack 128, delimiter stack 32); serialization is bounds-checked against tree-sitter's buffer limit.

</details>

<details>
<summary>Language bindings</summary>

| Binding | Status |
| ------- | ------ |
| C       | `src/parser.c` + `src/scanner.c`; CMake and Makefile builds verified |
| Rust    | `cargo test` — grammar load test and doc test pass |
| Go      | `bindings/go` — `go test ./...` passes |
| Python  | `pip install .` — `bindings/python/tests/test_binding.py` passes |
| Node.js | `bindings/node` — `index.d.ts` type-checks under `tsc --strict` and the native module compiles with node-gyp; the JS binding test itself is blocked upstream: the `tree-sitter` JS runtime (latest 0.25.1) ships no prebuild for Node 26's ABI |
| Zig     | `zig build` / `zig build test` — static library and binding test pass (Zig 0.16) |
| Swift   | `Package.swift` + `bindings/swift` — present but **not verified**: no Swift toolchain was available in the development environment |

</details>

<details>
<summary>Attribution</summary>

The grammar's structure and the external scanner's logic are adapted from [tree-sitter-python](https://github.com/tree-sitter/tree-sitter-python) (MIT License, Copyright (c) 2014 Max Brunsfeld); the adaptation is noted in `src/scanner.c`. Everything else in this repository is Qompass AI work under the license below.

</details>

## License

Apache License, Version 2.0 — see [LICENSE](./LICENSE).

Copyright 2026 Qompass AI
