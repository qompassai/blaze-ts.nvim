-- blaze-ts.nvim/lua/blaze-ts/config.lua
----------------------------------------
local M = {}

function M.setup_ts(opts)
  opts = opts or {}
  local ts_success, ts_configs = pcall(require, "nvim-treesitter.configs")
  if not ts_success then
    vim.notify("nvim-treesitter not available", vim.log.levels.WARN)
    return
  end

  local plugin_path = vim.fn.stdpath("data") .. "/lazy/blaze-ts.nvim"
  if vim.fn.isdirectory(plugin_path .. "/runtime") == 1 then
    vim.opt.runtimepath:prepend(plugin_path .. "/runtime")
  end
  local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
  parser_config.mojo = {
    install_info = {
      url = "https://github.com/qompassai/blaze-ts.nvim",
      files = { "src/parser.c", "src/grammar.js" },
      branch = "main",
      requires_generate_from_grammar = false,
    },
    filetype = { "mojo", "🔥" },
    maintainers = { "@qompassai" },
  }
  ts_configs.setup({
    highlight = {
      enable = opts.highlight ~= false,
      disable = opts.disable_highlight or {},
      additional_vim_regex_highlighting = false,
    },
    indent = {
      enable = opts.indent ~= false,
    },
    fold = {
      enable = opts.fold ~= false,
    },
    incremental_selection = {
      enable = opts.incremental_selection ~= false,
      keymaps = opts.selection_keymaps or {
        init_selection = "<C-space>",
        node_incremental = "<C-space>",
        node_decremental = "<bs>",
        scope_incremental = "<C-s>",
      },
    },
    query_linting = {
      enable = opts.query_linting ~= false,
      use_virtual_text = true,
    },
    ensure_installed = opts.ensure_installed or { "mojo" },
    sync_install = opts.sync_install or false,
    ignore_install = opts.ignore_install or {},
    auto_install = opts.auto_install ~= false,
    modules = opts.modules or {},
  })

  vim.defer_fn(function()
    local queries = { "highlights", "indents", "folds", "locals" }
    for _, query_type in ipairs(queries) do
      local query = vim.treesitter.query.get(query_type, "mojo")
      if query then
        vim.notify("Loaded " .. query_type .. ".scm for mojo", vim.log.levels.DEBUG)
      end
    end
  end, 100)
end

function M.setup_conform(opts)
  opts = opts or {}
  local conform_success, conform = pcall(require, "conform")
  if not conform_success then
    vim.notify("conform.nvim not available", vim.log.levels.WARN)
    return
  end

  conform.formatters = conform.formatters or {}
  conform.formatters.mojo_fmt = {
    meta = {
      url = "https://docs.modular.com/mojo/cli/format",
      description = "Official Formatter for The Mojo Programming Language",
    },
    command = "mojo",
    args = function(self, ctx)
      local args = { "format", "-q" }
      if opts.line_length then
        table.insert(args, "--line-length")
        table.insert(args, tostring(opts.line_length))
      end
      if opts.indent_width then
        table.insert(args, "--indent-width")
        table.insert(args, tostring(opts.indent_width))
      end
      table.insert(args, "$FILENAME")
      return args
    end,
    stdin = false,
    exit_codes = { 0, 1 },
  }
  conform.setup({
    formatters_by_ft = {
      ["mojo"] = { "mojo_fmt" },
      ["🔥"] = { "mojo_fmt" },
    },
    format_on_save = opts.format_on_save or {
      timeout_ms = 500,
      lsp_fallback = true,
    },
    format_after_save = opts.format_after_save,
    log_level = vim.log.levels.WARN,
  })
end

function M.setup_lsp(opts)
  opts = opts or {}
  local lspconfig_success, lspconfig = pcall(require, "lspconfig")
  if not lspconfig_success then
    vim.notify("lspconfig not available", vim.log.levels.WARN)
    return
  end

  if opts.mojo_lsp ~= false then
    if vim.fn.executable("mojo-lsp-server") == 1 then
      lspconfig.mojo.setup({
        on_attach = opts.on_attach,
        capabilities = opts.capabilities,
        filetypes = { "mojo" },
        settings = opts.mojo_settings or {},
      })
    else
      vim.notify("mojo-lsp-server not found, skipping LSP setup", vim.log.levels.INFO)
    end
  end
end

function M.setup_completion(opts)
  opts = opts or {}
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "mojo", "🔥" },
    callback = function()
      if vim.fn.exists("&omnifunc") then
        vim.bo.omnifunc = "v:lua.vim.lsp.omnifunc"
      end

      if opts.completion_settings then
        for key, value in pairs(opts.completion_settings) do
          vim.opt_local[key] = value
        end
      end
    end,
  })
end

function M.setup_diagnostics(opts)
  opts = opts or {}

  vim.diagnostic.config({
    virtual_text = opts.virtual_text ~= false,
    signs = opts.signs ~= false,
    underline = opts.underline ~= false,
    update_in_insert = opts.update_in_insert or false,
    severity_sort = opts.severity_sort ~= false,
    float = opts.float or {
      border = "rounded",
      source = "if_many",
    },
  })
end
function M.setup_keymaps(opts)
  opts = opts or {}
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "mojo", "🔥" },
    callback = function()
      local buf = vim.api.nvim_get_current_buf()

      vim.keymap.set("n", opts.format_keymap or "<leader>f", function()
        local conform_success, conform = pcall(require, "conform")
        if conform_success then
          conform.format({ bufnr = buf })
        else
          vim.lsp.buf.format({ bufnr = buf })
        end
      end, { buffer = buf, desc = "Format Mojo file" })

      if opts.lsp_keymaps ~= false then
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = buf, desc = "Go to definition" })
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { buffer = buf, desc = "Go to declaration" })
        vim.keymap.set("n", "gr", vim.lsp.buf.references, { buffer = buf, desc = "Find references" })
        vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = buf, desc = "Hover documentation" })
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { buffer = buf, desc = "Rename symbol" })
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = buf, desc = "Code actions" })
      end

      if opts.custom_keymaps then
        for keymap, action in pairs(opts.custom_keymaps) do
          vim.keymap.set("n", keymap, action, { buffer = buf })
        end
      end
    end,
  })
end

function M.setup_filetype(opts)
  opts = opts or {}

  vim.filetype.add({
    extension = {
      mojo = "mojo",
      ["🔥"] = "mojo",
    },
    filename = opts.filename_patterns or {},
    pattern = opts.file_patterns or {},
  })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "mojo", "🔥" },
    callback = function()
      if opts.buffer_options then
        for option, value in pairs(opts.buffer_options) do
          vim.opt_local[option] = value
        end
      else
        vim.opt_local.tabstop = 4
        vim.opt_local.shiftwidth = 4
        vim.opt_local.expandtab = true
        vim.opt_local.autoindent = true
        vim.opt_local.smartindent = true
      end
    end,
  })
end

function M.setup(opts)
  opts = opts or {}

  M.setup_filetype(opts.filetype or {})

  if opts.ts ~= false then
    M.setup_ts(opts.ts or {})
  end

  if opts.conform ~= false then
    M.setup_conform(opts.conform or {})
  end

  if opts.lsp ~= false then
    M.setup_lsp(opts.lsp or {})
  end

  if opts.completion ~= false then
    M.setup_completion(opts.completion or {})
  end

  if opts.diagnostics ~= false then
    M.setup_diagnostics(opts.diagnostics or {})
  end

  if opts.keymaps ~= false then
    M.setup_keymaps(opts.keymaps or {})
  end

  vim.notify("blaze-ts config setup completed", vim.log.levels.INFO)
end

return M
