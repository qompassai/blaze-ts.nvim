# ~/.GH/Qompass/Lua/Blaze-ts.nvim/flake.nix
# -----------------------------------------
# Copyright (C) 2025 Qompass AI, All rights reserved
{
  description = "Performant, batteries-included completion plugin for Neovim";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {
    flake-parts,
    nixpkgs,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];

      perSystem = {
        self,
        config,
        self',
        inputs',
        pkgs,
        system,
        lib,
        ...
      }: {
        _module.args.pkgs = import nixpkgs {
          inherit system;
          overlays = [inputs.fenix.overlays.default];
        };
        packages = let
          fs = lib.fileset;
          nixFs = fs.fileFilter (file: file.hasExt == "nix") ./.;
          rustFs = fs.unions [
            (fs.fileFilter (file: lib.hasPrefix "Cargo" file.name) ./.)
            (fs.fileFilter (file: file.hasExt "rs") ./.)
            ./.cargo
            ./rust-toolchain.toml
          ];
          # nvim source files
          # all that are not nix, nor rust, nor other ignored files
          nvimFs =
            fs.difference ./. (fs.unions [nixFs rustFs ./doc ./repro.lua]);
          version = "1.3.1";
        in {
          blink-fuzzy-lib = let
            inherit (inputs'.fenix.packages.minimal) toolchain;
            rustPlatform = pkgs.makeRustPlatform {
              cargo = toolchain;
              rustc = toolchain;
            };
          in
            rustPlatform.buildRustPackage {
              pname = "blink-fuzzy-lib";
              inherit version;
              src = fs.toSource {
                root = ./.;
                fileset = rustFs;
              };
              cargoLock = {lockFile = ./Cargo.lock;};
              buildInputs = with pkgs; lib.optionals stdenv.hostPlatform.isAarch64 [rust-jemalloc-sys]; # revisit once https://github.com/NixOS/nix/issues/12426 is solved
              nativeBuildInputs = with pkgs; [git];
            };

          blink-cmp = pkgs.vimUtils.buildVimPlugin {
            pname = "blink-cmp";
            inherit version;
            src = fs.toSource {
              root = ./.;
              fileset = nvimFs;
            };
            preInstall = ''
              mkdir -p target/release
              ln -s ${self'.packages.blink-fuzzy-lib}/lib/libblink_cmp_fuzzy.* target/release/
            '';
          };

          default = self'.packages.blink-cmp;
        };

        # builds the native module of the plugin
        apps.build-plugin = {
          type = "app";
          program = let
            buildScript = pkgs.writeShellApplication {
              name = "build-plugin";
              runtimeInputs = with pkgs; [fenix.minimal.toolchain gcc];
              text = ''
                export LIBRARY_PATH="${lib.makeLibraryPath [pkgs.libiconv]}";
                cargo build --release
              '';
            };
          in (lib.getExe buildScript);
        };

        devShells.default = pkgs.mkShell {
          name = "blaze-ts.nvim";
          inputsFrom = [
            self'.packages.blink-fuzzy-lib
            self'.packages.blink-cmp
            self'.apps.build-plugin
          ];
          packages = with pkgs; [rust-analyzer-nightly];
        };
        formatter = pkgs.nixfmt-classic;
      };
    };
  nixConfig = {
    extra-substituters = ["https://nix-community.cachix.org"];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs"
    ];
  };
}
