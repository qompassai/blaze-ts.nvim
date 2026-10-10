-- -------------------------------------------------------------------------------
-- /qompassai/blaze-ts.nvim/lua/blaze-ts/ui.lua
-- Qompass AI UI options store
-- SPDX-License-Identifier: Apache-2.0
-- Copyright (c) 2026 Qompass AI
--
-- Licensed under the Apache License, Version 2.0 (the "License"); you may not
-- use this file except in compliance with the License. You may obtain a copy
-- of the License at http://www.apache.org/licenses/LICENSE-2.0
-- -------------------------------------------------------------------------------
-- luacheck: globals vim

local M = {}
M.options = {
	highlight = true,
	indent = true,
	incremental_selection = true,
	auto_install = true,
	format_on_save = false,
	lsp_enabled = true,
}
M.original_options = vim.deepcopy(M.options)
return M
