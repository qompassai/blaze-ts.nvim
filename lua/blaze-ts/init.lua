-- blaze-ts.nvim/lua/blaze-ts/init.lua
local M = {}
function M.setup(opts)
  opts = opts or {}

  vim.filetype.add({
    extension = {
      mojo = "mojo",
      ["🔥"] = "mojo",
    }
  })

 local parser = require("blaze-ts.parser")
  parser.setup_parser_paths()

  if not parser.get_parser_path() then
    parser.install_parser()
  end
  ---@class parser_config
  ---@field install_info table
  ---@field url string
  ---@field files string
  ---@field generate_requires_npm boolean
  ---@field requires_generate_from_grammar boolean
  ---@field filetype string
  local parser_config = require('nvim-treesitter.parsers').get_parser_configs()
  parser_config.mojo = {
    install_info = {
      url = "https://github.com/qompassai/blaze-ts.nvim",
      files = { "src/parser.c", "src/grammar.js" },
      branch = "main",
      generate_requires_npm = true,
      requires_generate_from_grammar = true,
    },
    filetype = "mojo",
  }
  if opts.config ~= false then
    require("blaze-ts.config").setup(opts.config or {})
  end

  if opts.lsp ~= false then
    require("blaze-ts.lsp").setup(opts.lsp or {})
  end

  return M
end

return M
