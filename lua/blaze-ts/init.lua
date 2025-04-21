--- blaze-ts.nvim/lua/blaze-ts/init.lua
---------------------------------------
local M = {}
---
function M.setup(opts)
  opts = opts or {}
---
  local blaze_lib = require("blaze_lib")
---
blaze_lib.load()
blaze_lib.setup_runtime()
local env = blaze_lib.detect_environment()
vim.g.blaze_ts = vim.g.blaze_ts or {}
if env.mojo.has_pixi and env.pixi.has_pixi then
  vim.g.mojo_pixi_enabled = true
  vim.g.blaze_ts.pixi_path = env.pixi.bin_path
end
if env.gpu.has_nvidia then
  vim.g.blaze_ts.has_gpu = true
  vim.g.blaze_ts.cuda_version = env.gpu.cuda_version
end
if env.gpu.has_nvidia then
  vim.g.mojo_has_gpu = true
  vim.g.mojo_cuda_version = env.gpu.cuda_version
  if env.gpu.cuda_version then
    vim.notify("NVIDIA GPU detected with CUDA " .. env.gpu.cuda_version, vim.log.levels.INFO)
  end
end
---
  vim.filetype.add({
    extension = {
      mojo = "mojo",
      ["🔥"] = "mojo",
    }
  })
---
 local parser = require("blaze-ts.parser")
  parser.setup_parser_paths()
  if not parser.get_parser_path() then
    parser.install_parser()
  end

  function M.setup_utils()
  require("blaze-ts.utils").setup()
end

---@class parser_config
---@field install_info parser_src
---@field filetype string
  local parser_config = require('nvim-treesitter.parsers').get_parser_configs()
---@class parser_src
---@field url string
---@field files string[]
---@field branch string
---@field generate_requires_npm boolean
---@field requires_generate_from_grammar boolean
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
---
end
return M
