{ pkgs ? import <nixpkgs> {} }:

let
  currentSystem = pkgs.stdenv.hostPlatform.system;

  crossTargets = {
    "x86_64-linux" = "x86_64-unknown-linux-gnu";
    "x86_64-windows" = "x86_64-pc-windows-gnu";
    "aarch64-linux" = "aarch64-unknown-linux-gnu";
  };

  pixiSrc = pkgs.fetchFromGitHub {
    owner = "prefix-dev";
    repo = "pixi";
    rev = "d0146fba19d7e77d5ce04beb7896863c91707091";
    sha256 = "";
  };

  rustToolchain = pkgs.rust-bin.stable.latest.default.override {
    targets = [ "x86_64-unknown-linux-gnu" ];
  };

in
pkgs.mkShell {
  name = "blaze-ts-dev";

  buildInputs = with pkgs; [
    cargo-zigbuild
    zig
    gcc
    pkgsCross.mingwW64.buildPackages.gcc
    nodejs_22
    tree-sitter-cli
    zlib
    openssl
  ];

  RUST_BACKTRACE = "full";
  CARGO_BUILD_TARGET = crossTargets.${currentSystem} or "native";
  RUSTFLAGS = "-C target-cpu=native";

  shellHook = ''
    echo "🔥 Blaze-ts.nvim development environment activated"
    echo "Building for target: $CARGO_BUILD_TARGET"
    echo "Available tools:"
    echo "- Rust $(rustc --version)"
    echo "- Cargo $(cargo --version)"
    echo "- Zig $(zig version)"
    echo "- Node.js $(node --version)"
    
    # Set up pixi dependency
    export PIXI_PATH="${pixiSrc}"
    export CARGO_NET_GIT_FETCH_WITH_CLI = true
  '';

  SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
}

