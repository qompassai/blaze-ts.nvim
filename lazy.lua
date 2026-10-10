-- -------------------------------------------------------------------------------
-- /qompassai/blaze-ts.nvim/lazy.lua
-- Qompass AI lazy.nvim plugin spec
-- SPDX-License-Identifier: Apache-2.0
-- Copyright (c) 2026 Qompass AI
--
-- Licensed under the Apache License, Version 2.0 (the "License"); you may not
-- use this file except in compliance with the License. You may obtain a copy
-- of the License at http://www.apache.org/licenses/LICENSE-2.0
-- -------------------------------------------------------------------------------

return {
  "qompassai/blaze-ts.nvim",
  lazy = true,
  ft   = { "mojo", "🔥" },
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-lua/plenary.nvim',
  },
  cmd = {
    "BlazeTS",
    "BlazeHealth",
    "BlazeParserHealth",
    "BlazeReinstallParser",
  },

  ---@type table
  opts = {
    parser = { auto_install = true },
    nvim_treesitter = {
      highlight = { enable = true, additional_vim_regex_highlighting = false },
      indent    = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection    = "<C-space>",
          node_incremental  = "<C-space>",
          node_decremental  = "<BS>",
        },
      },
      parser_config = {
        mojo = {
          install_info = {
            url   = "https://github.com/qompassai/blaze-ts.nvim",
            files = {
              "src/parser.c",
              "src/scanner.c",
            },
            branch = "main",
            requires_generate_from_grammar = false,
          },
          filetype    = { "mojo", "🔥" },
          maintainers = { "@qompassai" },
        },
      },
    },
  },
  config = function(_, opts)
    local ok, treesitter = pcall(require, "nvim-treesitter.configs")
    if not ok then
      vim.notify("nvim-treesitter not available", vim.log.levels.WARN)
      return
    end
    if opts.nvim_treesitter and opts.nvim_treesitter.parser_config then
      local ok_p, parsers_mod = pcall(require, "nvim-treesitter.parsers")
      if ok_p and type(parsers_mod.get_parser_configs) == "function" then
        local pcfg = parsers_mod.get_parser_configs()
        for lang, cfg in pairs(opts.nvim_treesitter.parser_config) do
          pcfg[lang] = cfg
        end
      end
    end
    treesitter.setup(opts.nvim_treesitter or {})
    require("blaze-ts").setup(opts)
  end,

  keys = {
    {
      "<leader>mh",
      function() require("blaze-ts").health_check() end,
      desc = "Blaze‑TS health check",
      ft   = { "mojo", "🔥" },
    },
    {
      "<leader>mp",
      function() require("blaze-ts").parser_health() end,
      desc = "Mojo parser health",
      ft   = { "mojo", "🔥" },
    },
    {
      "<leader>mr",
      function() vim.cmd("BlazeReinstallParser") end,
      desc = "Reinstall Mojo parser",
      ft   = { "mojo", "🔥" },
    },
  },
}
