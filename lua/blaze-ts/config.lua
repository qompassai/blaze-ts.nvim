-- blaze-ts.nvim/lua/blaze-ts/config.lua
local M = {}

function M.setup_treesitter(opts)
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

function M.setup_conform(opts)
  opts = opts or {}
  local conform_ok, conform = pcall(require, "conform")
  if not conform_ok then
    vim.notify("conform.nvim not available for Mojo formatting", vim.log.levels.WARN)
    return
  end
  ---@diagnostic disable-next-line: undefined-field
  conform.setup({
    formatters_by_ft = {
      ["mojo"] = { "mojo_fmt" },
      ["🔥"] = { "mojo_fmt" }
    },
    formatters = {
      mojo_fmt = {
        command = opts.command or "mojo",
        args = opts.args or { "format", "$FILENAME" },
        stdin = opts.stdin or false,
        timeout_ms = opts.timeout_ms or 1000,
        exit_codes = opts.exit_codes or { 0 },
      }
    },
    format_on_save = opts.format_on_save,
  })
  
  if opts.setup_keymaps then
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
end

function M.setup(opts)
  opts = opts or {}
  
  if opts.treesitter ~= false then
    M.setup_treesitter(opts.treesitter or {})
  end
  
  if opts.conform ~= false then
    M.setup_conform(opts.conform or {})
  end
  
  return M
end

return M
