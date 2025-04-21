-- lua/blaze-ts/config_ui.lua
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

