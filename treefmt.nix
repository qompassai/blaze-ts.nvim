# /qompassai/Nur/treefmt.nix
# ----------------------
# Copyright (C) 2025 Qompass AI, All rights reserved
{
  projectRootFile = "flake.nix";
  programs = {
    alejandra.enable = true;
    shellcheck.enable = true;
    shfmt.enable = true;
  };
}
