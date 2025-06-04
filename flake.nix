#  /qompassai/blaze-ts.nvim/flake.nix
# Copyright (C) 2025 Qompass AI, All rights reserved
#
{
  description = " Blaze-ts.nvim: A 🔥 Tree-Sitter parser for Mojo";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    tree-sitter.url = "github:tree-sitter/tree-sitter";
    blaze-ts.url = "github:qompassai/blaze-ts.nvim?ref=main";
  };

  outputs = { self, nixpkgs, flake-utils, tree-sitter, blaze-ts }:
    flake-utils.lib.eachSystem [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "x86_64-windows"
      "aarch64-windows"
    ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ tree-sitter.overlays.default ];
        };

        nodeEnv = pkgs.nodePackages_latest;

        mojo-parser = pkgs.tree-sitter.buildGrammar {
          language = "mojo";
          version = "0.1.0";
          src = ./.;
          buildPhase = ''
            export HOME=$TMPDIR
            ${nodeEnv.node-gyp}/bin/node-gyp configure
            ${nodeEnv.node-gyp}/bin/node-gyp build
            tree-sitter generate
            tree-sitter build-wasm
            zig build -Doptimize=ReleaseSafe
          '';
          installPhase = ''
            mkdir -p $out/{parser,queries,bindings}
            cp -r src tree-sitter-mojo.wasm $out/
            cp -r bindings/node $out/bindings/
            cp queries/* $out/queries/
          '';
          nativeBuildInputs = with pkgs; [
            nodeEnv.node-gyp
            nodeEnv.tree-sitter-cli
            zig
            gcc
          ];
          meta = with pkgs.lib; {
            description = "Blaze-ts.nvim: A 🔥 Tree-Sitter parser for Mojo programming language";
            longDescription = ''
              Derived from:
              • Modular (https://github.com/modular)
              • mojo.vim (Apache-2.0)
              • mojo-syntax (MIT)
              • pixi (BSD-3)
              • magic-docker

              LICENSING NOTICE:
              • Modular Mojo Lang: Licensed under Modular's Apache 2.0 license
              • Qompass AI packaging, build scripts, and configuration: Dual-licensed under:
                - GNU AGPL v3.0 for non-commercial, open-source use
                - Qompass Commercial Distribution Agreement (Q-CDA) v1.0 for commercial use
            '';
            homepage = "https://developer.nvidia.com/hpc-sdk";
            downloadPage = "https://developer.nvidia.com/hpc-sdk-downloads";
            license = with licenses; [
              agpl3Only
              {
                fullName = "Qompass AI Commercial Distribution Agreement v1.0";
                shortName = "Q-CDA-1.0";
                spdxId = "Q-CDA-1.0";
                url = "https://github.com/qompassai/nur/blob/main/LICENSE-QCDA";
                free = false;
                redistributable = true;
              }
              unfree
            ];
            sourceProvenance = with sourceTypes; [
              binaryNativeCode
              binaryBytecode
              fromSource
            ];
            maintainers = [
              {
                github = "qompassai";
                githubId = 137334444;
                name = "Qompass AI";
              }
              maintainers.phaedrusflow
            ];
            platforms = [
              "x86_64-linux"
              "aarch64-linux"
              "x86_64-darwin"
              "x86_64-windows"
              "aarch64-windows"
            ];
            outputsToInstall = [ "out" ];
            mainProgram = "nvc";
            timeout = 7200;
            broken = false;
            badPlatforms = [ ];
            knownVulnerabilities = [ ];
          };
        };

      in
      {
        packages = {
          default = mojo-parser;
          mojo = mojo-parser;
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            nodejs
            tree-sitter
            gcc
          ] ++ pkgs.lib.optionals (system == "x86_64-windows" || system == "aarch64-windows") [
            pkgs.pkgsCross.mingw32.buildPackages.gcc
          ];
        };

        checks = {
          build = mojo-parser;
          test = pkgs.runCommand "test-mojo-parser" { } ''
            ${mojo-parser}/bin/tree-sitter parse ${./test}/*.mojo
            touch $out
          '';
        };
      }
    ) // {
      overlays = {
        default = _: prev: {
          vimPlugins = prev.vimPlugins // {
            blaze-ts = prev.vimPlugins.buildVimPlugin {
              name = "blaze-ts.nvim";
              src = blaze-ts;
            };
          };
        };
      };
    };
}
