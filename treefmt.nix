# -------------------------------------------------------------------------------
# /qompassai/blaze-ts.nvim/treefmt.nix
# Qompass AI treefmt configuration
# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2026 Qompass AI
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0
# -------------------------------------------------------------------------------

{
  projectRootFile = "flake.nix";
  programs = {
    alejandra.enable = true;
    shellcheck.enable = true;
    shfmt.enable = true;
  };
}
