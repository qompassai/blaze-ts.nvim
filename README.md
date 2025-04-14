# 🔥-ts

## 🔥 Tree-sitter

<p align="center">
  <a href="https://www.gnu.org/licenses/agpl-3.0">
    <img src="https://img.shields.io/badge/License-AGPL%20v3-blue.svg" alt="License: AGPL v3">
  </a>
  <a href="./LICENSE-QCDA">
    <img src="https://img.shields.io/badge/license-Q--CDA-lightgrey.svg" alt="License: Q-CDA">
  </a>
</p>

---

## ✨ Overview

This repository provides a [Tree-sitter](https://tree-sitter.github.io) grammar for [Mojo](https://www.modular.com/mojo), a language designed for AI and systems programming.

Used by the [`🔥.nvim`](https://github.com/qompassai/🔥.nvim) Neovim plugin for:

- 🌈 Syntax highlighting
- 🔬 Incremental parsing
- 🎯 Smart indentation
- 🧠 Semantic analysis

---

## 📦 Installation

Clone this repo and build the parser:

```bash
git clone https://github.com/qompassai/🔥-ts
cd 🔥-ts
tree-sitter generate
tree-sitter test

