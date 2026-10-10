# Contributing to blaze-ts.nvim

Thank you for your interest in contributing to **blaze-ts**, the Tree-sitter grammar for the Mojo language. Whether you're fixing bugs, improving the grammar, writing tests, or helping with docs — every contribution counts! 🔥

---

## 🛠 Getting Started

1. **Clone the Repository**

   ```bash
   git clone https://github.com/qompassai/blaze-ts.nvim
   cd blaze-ts.nvim
   ```

2. **Install Requirements**

   - `node` (for grammar testing and dev)
   - Optionally: `wasm-pack`, `prebuildify`, `node-gyp`

3. **Build the Grammar**

   ```bash
   tree-sitter generate
   tree-sitter test
   ```

4. **Make Your Changes**

   - Follow the Tree-sitter grammar structure (`grammar.js`, `src/`, `bindings/`)
   - Keep indentation to **2 spaces**
   - Use `camelCase` for JS identifiers

5. **Run Tests**

   ```bash
   tree-sitter test
   ```

6. **Commit & Push**

   ```bash
   git commit -m "fix(grammar): improve struct matching"
   git push origin feat/my-change
   ```

7. **Open a Pull Request**
   - Clearly describe what changed and why
   - Reference any related issues or limitations

---

## 📁 Structure Overview

- `grammar.js` — main Tree-sitter grammar definition
- `src/` — generated parser code
- `bindings/` — language-specific bindings (C, Node, Python, Rust, etc.)
- `queries/` — highlight and capture queries (`highlights.scm`, etc.)

---

## 🔍 Developer Tools

| Tool          | Purpose                         |
| ------------- | ------------------------------- |
| `tree-sitter` | CLI to build/test grammar       |
| `wasm-pack`   | Builds wasm bindings (optional) |
| `node-gyp`    | For native Node.js bindings     |
| `prebuildify` | To bundle multi-platform builds |

---

## 📜 License

All contributions are licensed under the Apache License, Version 2.0, the license of this repository. See `LICENSE` for details.
