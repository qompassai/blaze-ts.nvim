-- -------------------------------------------------------------------------------
-- /qompassai/blaze-ts.nvim/plugin/blaze-ts.lua
-- Qompass AI Neovim plugin loader
-- SPDX-License-Identifier: Apache-2.0
-- Copyright (c) 2026 Qompass AI
--
-- Licensed under the Apache License, Version 2.0 (the "License"); you may not
-- use this file except in compliance with the License. You may obtain a copy
-- of the License at http://www.apache.org/licenses/LICENSE-2.0
-- -------------------------------------------------------------------------------

if vim.fn.has("nvim-0.10") ~= 1 then
    vim.api.nvim_err_writeln("blaze-ts.nvim requires Neovim >= 0.10")
    return
end

if vim.g.loaded_blaze_ts == 1 then
    return
end
vim.g.loaded_blaze_ts = 1

vim.api.nvim_create_user_command("BlazeTS", function()
    require("blaze-ts").setup()
end, { desc = "Set up blaze-ts.nvim (Mojo tree-sitter support)" })

vim.api.nvim_create_user_command("BlazeHealth", function()
    require("blaze-ts").health_check()
end, { desc = "blaze-ts.nvim health check" })

vim.api.nvim_create_user_command("BlazeParserHealth", function()
    require("blaze-ts").parser_health()
end, { desc = "Mojo parser health" })

vim.api.nvim_create_user_command("BlazeReinstallParser", function()
    require("blaze-ts").reinstall_parser()
end, { desc = "Reinstall or re-register the Mojo parser" })

vim.api.nvim_create_autocmd("FileType", {
    pattern = "mojo",
    once = true,
    callback = function()
        if pcall(vim.treesitter.get_parser, 0, "mojo") then
            return
        end
        -- Core Neovim cannot install parsers; only offer the install when
        -- nvim-treesitter is actually present to perform it.
        if vim.fn.exists(":TSInstall") == 2 then
            vim.schedule(function()
                local ok = pcall(vim.cmd, "TSInstall mojo")
                if not ok then
                    vim.notify(
                        "blaze-ts: failed to install the Mojo parser; run :BlazeParserHealth for details",
                        vim.log.levels.WARN
                    )
                end
            end)
        end
    end,
})
