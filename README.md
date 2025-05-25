<!-- /qompassai/blaze-ts.nvim/README.md -->
<!-- ---------------------------- -->
<!-- Copyright (C) 2025 Qompass AI, All rights reserved -->

<h1 align="center">Qompass AI Blaze-ts.nvim</h1>
<h2 align="center">A 🔥 Tree-sitter</h2>
## 🔥 Tree-sitter

<p align="center">
<a href="https://www.lua.org/"><img src="https://img.shields.io/badge/Lua-2C2D72?style=for-the-badge&logo=lua&logoColor=white" alt="Lua"></a>
  <br>
  <a href="https://www.lua.org/docs.html"><img src="https://img.shields.io/badge/Lua-Documentation-blue?style=flat-square" alt="Lua Documentation"></a>
  <a href="https://github.com/topics/lua-tutorial"><img src="https://img.shields.io/badge/Lua-Tutorials-green?style=flat-square" alt="Lua Tutorials"></a>
  <br>
  <a href="https://www.gnu.org/licenses/agpl-3.0">
    <img src="https://img.shields.io/badge/License-AGPL%20v3-blue.svg" alt="License: AGPL v3">
  </a>
  <a href="./LICENSE-QCDA">
    <img src="https://img.shields.io/badge/license-Q--CDA-lightgrey.svg" alt="License: Q-CDA">
  </a>
</p>

![Repository Views](https://komarev.com/ghpvc/?username=qompassai-blaze-ts.nvim)
![GitHub all releases](https://img.shields.io/github/downloads/qompassai/blaze-ts.nvim/total?style=flat-square)


---

## ✨ Overview

This repository provides a [Tree-sitter](https://tree-sitter.github.io) grammar for [Mojo](https://www.modular.com/mojo), a language designed for AI and systems programming.

Used by the [`blaze.nvim`](https://github.com/qompassai/blaze.nvim) Neovim plugin for:

- 🌈 Syntax highlighting
- 🔬 Incremental parsing
- 🎯 Smart indentation
- 🧠 Semantic analysis

---

## 📦 Installation

Clone this repo and build the parser:

```bash
git clone https://github.com/qompassai/blaze-ts.nvim
cd blaze-ts.nvim
tree-sitter generate
tree-sitter test

```
