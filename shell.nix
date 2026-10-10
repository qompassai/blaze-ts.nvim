# -------------------------------------------------------------------------------
# /qompassai/blaze-ts.nvim/shell.nix
# Qompass AI Nix shell compatibility shim
# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2026 Qompass AI
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy
# of the License at http://www.apache.org/licenses/LICENSE-2.0
# -------------------------------------------------------------------------------
# Compatibility shim for nix-shell: the flake is the source of truth.
# Prefer `nix develop`. This file just forwards to the flake's devShell.
(builtins.getFlake (toString ./.)).devShells.${builtins.currentSystem}.default
