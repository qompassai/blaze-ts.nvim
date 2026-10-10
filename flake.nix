# -------------------------------------------------------------------------------
# /qompassai/blaze-ts.nvim/flake.nix
# Qompass AI Nix flake
# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2026 Qompass AI
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0
# -------------------------------------------------------------------------------
# Packages:
#   default     — the Mojo parser (parser/mojo.so) and its queries, compiled
#                 from the checked-in generated C sources.
#   nvim-plugin — the full plugin tree as a Vim plugin package.
# Checks:
#   corpus      — the tree-sitter corpus suite (test/corpus).
#   queries     — every shipped query compiles against the grammar.
# devShell: the toolchains this repo builds with (tree-sitter CLI, Node,
# a C compiler, Rust, Go, Zig, Python).
{
  description = "blaze-ts.nvim: tree-sitter grammar and Neovim plugin for the Mojo language";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.stdenv.mkDerivation {
            pname = "tree-sitter-mojo";
            version = "0.1.1";
            src = ./.;

            buildPhase = ''
              runHook preBuild
              $CC -O2 -shared -fPIC -Isrc src/parser.c src/scanner.c -o mojo.so
              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall
              mkdir -p $out/parser $out/queries
              cp mojo.so $out/parser/mojo.so
              cp -r runtime/queries/mojo $out/queries/mojo
              runHook postInstall
            '';

            meta = {
              description = "Tree-sitter grammar for the Mojo language (parser and queries)";
              homepage = "https://github.com/qompassai/blaze-ts.nvim";
              license = pkgs.lib.licenses.asl20;
              platforms = systems;
            };
          };

          nvim-plugin = pkgs.vimUtils.buildVimPlugin {
            pname = "blaze-ts.nvim";
            version = "0.1.1";
            src = ./.;
            meta = {
              description = "Neovim plugin for Mojo tree-sitter support";
              homepage = "https://github.com/qompassai/blaze-ts.nvim";
              license = pkgs.lib.licenses.asl20;
              platforms = systems;
            };
          };
        }
      );

      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          corpus = pkgs.runCommand "blaze-ts-corpus-tests" { nativeBuildInputs = [ pkgs.gcc pkgs.tree-sitter ]; } ''
            export HOME=$TMPDIR
            cp -r ${./.} src
            chmod -R +w src
            cd src
            tree-sitter test
            touch $out
          '';

          queries =
            pkgs.runCommand "blaze-ts-query-checks"
              {
                nativeBuildInputs = [ pkgs.gcc pkgs.tree-sitter ];
              }
              ''
                export HOME=$TMPDIR
                cp -r ${./.} src
                chmod -R +w src
                cd src
                cat > sample.mojo <<'EOF'
                fn greet(name: String) -> String:
                    return f"hello {name}"
                EOF
                for q in highlights indents folds locals; do
                  tree-sitter query runtime/queries/mojo/$q.scm sample.mojo > /dev/null
                done
                touch $out
              '';
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              cargo
              gcc
              go
              nodejs
              python3
              rustc
              tree-sitter
              zig
            ];
          };
        }
      );
    };
}
