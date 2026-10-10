-- -------------------------------------------------------------------------------
-- /qompassai/blaze-ts.nvim/lua/blaze-ts/init.lua
-- Qompass AI Neovim plugin entry point
-- SPDX-License-Identifier: Apache-2.0
-- Copyright (c) 2026 Qompass AI
--
-- Licensed under the Apache License, Version 2.0 (the "License"); you may not
-- use this file except in compliance with the License. You may obtain a copy
-- of the License at http://www.apache.org/licenses/LICENSE-2.0
-- -------------------------------------------------------------------------------

local M = {}

local sep = package.config:sub(1, 1)

local function join(...)
    return table.concat({ ... }, sep)
end

--- Absolute path of the plugin root (this file is <root>/lua/blaze-ts/init.lua).
---@return string
local function plugin_root()
    local src = debug.getinfo(1, "S").source:sub(2)
    return vim.fn.fnamemodify(src, ":h:h:h")
end

--- Register the parser binary shipped in <root>/parser, native first.
---@param root string
---@return string|nil path the parser file that was registered, if any
local function register_bundled_parser(root)
    local candidates = { join(root, "parser", "mojo.so"), join(root, "parser", "mojo.wasm") }
    for _, path in ipairs(candidates) do
        if vim.fn.filereadable(path) == 1 then
            local ok = pcall(vim.treesitter.language.add, "mojo", { path = path })
            if ok then
                return path
            end
        end
    end
    return nil
end

--- Compile-check every query the plugin ships for the mojo language.
---@return table<string, boolean> status per query name
local function query_status()
    local status = {}
    for _, name in ipairs({ "folds", "highlights", "indents", "locals" }) do
        local ok, query = pcall(vim.treesitter.query.get, "mojo", name)
        status[name] = ok and query ~= nil
    end
    return status
end

local CONFIG_SECTIONS = { "completion", "conform", "diagnostics", "filetype", "keymaps", "lsp", "ts" }

---@param opts table|nil
---@return boolean true when opts carries any blaze-ts.config section table
local function wants_config(opts)
    for _, key in ipairs(CONFIG_SECTIONS) do
        if opts[key] ~= nil then
            return true
        end
    end
    return false
end

--- Set up the plugin: filetype, bundled parser, runtime path, parser config.
--- When opts contains blaze-ts.config sections (ts/conform/lsp/completion/
--- diagnostics/keymaps/filetype) they are forwarded to that module's setup.
---@param opts table|nil
---@return table status summary of what was registered
function M.setup(opts)
    opts = opts or {}
    local parser = require("blaze-ts.parser")

    vim.filetype.add({ extension = { mojo = "mojo", ["🔥"] = "mojo" } })
    parser.setup_runtime_path()
    local bundled = register_bundled_parser(plugin_root())
    local config_registered = parser.register_config()

    if wants_config(opts) then
        require("blaze-ts.config").setup(opts)
    end

    return { bundled_parser = bundled, parser_config_registered = config_registered }
end

--- Parser-only health: config registration, parser path, loadability.
---@return table status as returned by blaze-ts.parser.health()
function M.parser_health()
    local status = require("blaze-ts.parser").health()
    local lines = {
        "blaze-ts parser health:",
        "  config registered: " .. tostring(status.config),
        "  parser path: " .. tostring(status.path),
        "  installed: " .. tostring(status.installed),
        "  loadable: " .. tostring(status.loadable),
    }
    vim.notify(table.concat(lines, "\n"), status.loadable and vim.log.levels.INFO or vim.log.levels.WARN)
    return status
end

--- Full health: parser status, query compile status, Mojo environment probe.
---@return table status with parser/queries/environment fields
function M.health_check()
    local status = {
        environment = require("blaze-ts.utils").detect_environment(),
        parser = require("blaze-ts.parser").health(),
        queries = query_status(),
    }
    local lines = { "blaze-ts health:" }
    lines[#lines + 1] = "  parser loadable: " .. tostring(status.parser.loadable)
    for name, ok in pairs(status.queries) do
        lines[#lines + 1] = "  query " .. name .. ": " .. (ok and "ok" or "MISSING/INVALID")
    end
    lines[#lines + 1] = "  mojo executable: " .. tostring(status.environment.mojo.has_mojo)
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
    return status
end

--- Reinstall the Mojo parser: through nvim-treesitter when it is available
--- (:TSInstall! mojo), otherwise re-register the bundled parser binary.
---@return boolean ok
function M.reinstall_parser()
    if vim.fn.exists(":TSInstall") == 2 then
        local ok, err = pcall(vim.cmd, "TSInstall! mojo")
        if ok then
            vim.notify("blaze-ts: reinstalling Mojo parser via nvim-treesitter", vim.log.levels.INFO)
            return true
        end
        vim.notify("blaze-ts: TSInstall failed (" .. tostring(err) .. "); trying bundled parser", vim.log.levels.WARN)
    end
    local path = register_bundled_parser(plugin_root())
    if path then
        vim.notify("blaze-ts: re-registered bundled parser: " .. path, vim.log.levels.INFO)
        return true
    end
    vim.notify("blaze-ts: no bundled parser found and nvim-treesitter unavailable", vim.log.levels.ERROR)
    return false
end

return M
