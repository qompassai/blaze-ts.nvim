-- blaze-ts.nvim/lua/blaze-ts/parser.lua
----------------------------------------
local M = {}
--
function M.get_parser_path()
  local parser_path = vim.fn.stdpath("data") .. "/site/pack/packer/opt/nvim-treesitter/parser/mojo.so"
  if not vim.fn.filereadable(parser_path) then
    parser_path = vim.fn.stdpath("data") .. "/site/pack/lazy/opt/nvim-treesitter/parser/mojo.so"
  end
  if not vim.fn.filereadable(parser_path) then
    parser_path = vim.fn.expand("~/.local/share/nvim/site/parser/mojo.so")
  end
  return vim.fn.filereadable(parser_path) and parser_path or nil
end
--
function M.load_parser(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local lang = "mojo"
  local parser = vim.treesitter.get_parser(bufnr, lang)
  if not parser then
    vim.notify("Failed to load Mojo parser for current buffer", vim.log.levels.WARN)
    return nil
  end
  return parser
end
--
function M.get_tree(bufnr)
  local parser = M.load_parser(bufnr)
  if not parser then return nil end
  return parser:parse()[1]
end
--
function M.is_mojo_file(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype
  return ft == "mojo" or vim.fn.expand("%:e") == "mojo" or vim.fn.expand("%:e") == "🔥"
end
--
function M.install_parser()
  local ts_install = require("nvim-treesitter.install")
  local parser_name = "mojo"
  if ts_install.is_installed(parser_name) then
    vim.notify("Mojo parser is already installed", vim.log.levels.INFO)
    return true
  end
  local success = ts_install.install_parsers({parser_name})
  if success then
    vim.notify("Mojo parser installed successfully", vim.log.levels.INFO)
  else
    vim.notify("Failed to install Mojo parser", vim.log.levels.ERROR)
  end
  return success
end
--
function M.setup_parser_paths()
  local runtime_path = vim.fn.fnamemodify(vim.fn.expand("<sfile>"), ":p:h:h:h") .. "/runtime"
  if not vim.tbl_contains(vim.opt.rtp:get(), runtime_path) then
    vim.opt.rtp:prepend(runtime_path)
  end
--
end
---
return M
