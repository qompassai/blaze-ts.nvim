-- blaze-ts.nvim/lua/blaze-ts/config.lua
----------------------------------------
local M = {}
---
function M.setup_ts(opts)
  opts = opts or {}
  require("nvim-treesitter.configs").setup({
    highlight = {
      enable = opts.highlight ~= false,
      disable = opts.disable_highlight or {},
    },
    indent = {
      enable = opts.indent ~= false,
    },
    incremental_selection = {
      enable = opts.incremental_selection ~= false,
      keymaps = opts.selection_keymaps or {
        init_selection = "<C-space>",
        node_incremental = "<C-space>",
        node_decremental = "<bs>",
      },
    },
    ensure_installed = opts.ensure_installed or { "mojo" },
    sync_install = opts.sync_install or false,
    ignore_install = opts.ignore_install or {},
    auto_install = opts.auto_install ~= false,
    modules = opts.modules or {},
  })
end
---
function M.setup_conform(opts)
  opts = opts or {}
local conform_ok, _ = pcall(require, "conform")
  if not conform_ok then
    ---@type table
    local conform = require("conform")
---@diagnostic disable-next-line: undefined-field
  conform.formatters = conform.formatters or {}
  conform.formatters.mojo_fmt = {
    meta = {
      url = "https://docs.modular.com/mojo/cli/format",
      description = "Official Formatter for The Mojo Programming Language"
    },
    command = "mojo",
    ---@diagnostic disable-next-line: unused-local
    args = function(self, ctx)
      local args = { "format", "-q" }
      if opts.line_length then
        table.insert(args, "--line-length")
        table.insert(args, tostring(opts.line_length))
      end
      table.insert(args, "$FILENAME")
      return args
    end,
    stdin = false,
  }
    conform.setup({
    formatters_by_ft = {
      ["mojo"] = { "mojo_fmt" },
      ["🔥"] = { "mojo_fmt" }
    },
    format_on_save = opts.format_on_save,
  })
end
---
    vim.api.nvim_create_autocmd("FileType", {
    pattern = { "mojo", "🔥" },
    callback = function()
      vim.keymap.set("n", "<leader>f", function()
        ---@diagnostic disable-next-line: undefined-field
        require("conform").format({ bufnr = 0 })
      end, { buffer = true, desc = "Format Mojo file" })
    end
  })
end
---
function M.setup(opts)
  opts = opts or {}
  if opts.ts ~= false then
    M.setup_ts(opts.ts or {})
  end
  if opts.conform ~= false then
    M.setup_conform(opts.conform or {})
  end
 end
return M
