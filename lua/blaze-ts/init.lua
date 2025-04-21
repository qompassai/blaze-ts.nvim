--- blaze-ts.nvim/lua/blaze-ts/init.lua
---------------------------------------
local M = {}
---
function M.setup(opts)
  opts = opts or {}
  local current_dir = debug.getinfo(1).source:match("@?(.*/)") or "./"
  local parent_dir = current_dir .. "../"
  local blaze_lib = dofile(parent_dir .. "blaze_lib.lua")
  blaze_lib.load()
  if blaze_lib.setup_runtime then
    blaze_lib.setup_runtime()
  else
    local utils = require("blaze-ts.utils")
    utils.setup_ts_runtime_path()
  end
  local env = blaze_lib.detect_environment()
  vim.g.blaze_ts = vim.g.blaze_ts or {}
  if env.mojo and env.mojo.has_pixi and env.pixi and env.pixi.has_pixi then
    vim.g.mojo_pixi_enabled = true
    vim.g.blaze_ts.pixi_path = env.pixi.bin_path
  end
  if env.gpu and env.gpu.has_nvidia then
    vim.g.blaze_ts.has_gpu = true
    vim.g.blaze_ts.cuda_version = env.gpu.cuda_version
    vim.g.mojo_has_gpu = true
    vim.g.mojo_cuda_version = env.gpu.cuda_version
    if env.gpu.cuda_version then
      vim.notify("NVIDIA GPU detected with CUDA " .. env.gpu.cuda_version, vim.log.levels.INFO)
    end
  end
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
end
function M.setup_utils()
  local utils = require("blaze-ts.utils")
  if utils.setup then
    utils.setup()
  end
end
return M
