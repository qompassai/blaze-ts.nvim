-- blaze-ts.nvim/lua/blaze-ts/config.lua
-- ------------------------------------
-- luacheck: globals vim

local Config = {}

local function default(value, fallback)
  if value == nil then return fallback end
  return value
end
function Config.setup_ts(opts)
  opts = opts or {}

  local ok_ts, ts_configs = pcall(require, "nvim-treesitter.configs")
  if not ok_ts then
    vim.notify("nvim-treesitter not available", vim.log.levels.WARN)
    return
  end

  local plugin_path = vim.fn.stdpath("data") .. "/lazy/blaze-ts.nvim"
  if vim.fn.isdirectory(plugin_path .. "/runtime") == 1 then
    vim.opt.runtimepath:prepend(plugin_path .. "/runtime")
  end

  local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
  if not parser_config.mojo then
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
  end
  ts_configs.setup({
    highlight = {
      enable = default(opts.highlight, true),
      disable = opts.disable_highlight or {},
      additional_vim_regex_highlighting = false,
    },
    indent = { enable = default(opts.indent, true) },
    fold   = { enable = default(opts.fold, true)   },
    incremental_selection = {
      enable = default(opts.incremental_selection, true),
      keymaps = vim.tbl_extend("force", {
        init_selection    = "<C-space>",
        node_incremental  = "<C-space>",
        node_decremental  = "<BS>",
        scope_incremental = "<C-s>",
      }, opts.selection_keymaps or {}),
    },
    query_linter   = { enable = default(opts.query_linting, true), use_virtual_text = true },
    ensure_installed = opts.ensure_installed or { "mojo" },
    sync_install     = default(opts.sync_install, false),
    ignore_install   = opts.ignore_install or {},
    auto_install     = default(opts.auto_install, true),
    modules          = opts.modules or {},
  })
  vim.defer_fn(function()
    for _, q in ipairs({ "highlights", "indents", "folds", "locals" }) do
      if vim.treesitter.query.get(q, "mojo") then
        vim.notify("Loaded " .. q .. ".scm for mojo", vim.log.levels.DEBUG)
      end
    end
  end, 100)
end
function Config.setup_conform(opts)
  opts = opts or {}
  local ok_cf, conform = pcall(require, "conform")
  if not ok_cf then
    vim.notify("conform.nvim not available", vim.log.levels.WARN)
    return
  end
  conform.formatters = conform.formatters or {}
  conform.formatters.mojo_fmt = {
    meta = {
      url = "https://docs.modular.com/mojo/cli/format",
      description = "Official formatter for the Mojo programming language",
    },
    command = "mojo",
    args = function(_, _)
      local a = { "format", "-q" }
      if opts.line_length then
        vim.list_extend(a, { "--line-length", tostring(opts.line_length) })
      end
      if opts.indent_width then
        vim.list_extend(a, { "--indent-width", tostring(opts.indent_width) })
      end
      table.insert(a, "$FILENAME")
      return a
    end,
    stdin       = false,
    exit_codes  = { 0, 1 },
  }
  conform.setup({
    formatters_by_ft = { mojo = { "mojo_fmt" }, ["🔥"] = { "mojo_fmt" } },
    format_on_save   = vim.tbl_extend("force", {
      timeout_ms   = 500,
      lsp_fallback = true,
    }, opts.format_on_save or {}),
    format_after_save = opts.format_after_save,
    log_level         = vim.log.levels.WARN,
  })
end
function Config.setup_lsp(opts)
  opts = opts or {}
  local ok_lsp, lspconfig = pcall(require, "lspconfig")
  if not ok_lsp then
    vim.notify("lspconfig not available", vim.log.levels.WARN)
    return
  end
  local configs = require("lspconfig.configs")
  if not configs.mojo then
    configs.mojo = {
      default_config = {
        cmd       = { "mojo-lsp-server" },
        filetypes = { "mojo", "🔥" },
        root_dir  = lspconfig.util.root_pattern("modular.yaml", ".git"),
        settings  = {},
      },
    }
  end
  if opts.mojo_lsp == false then return end
  if vim.fn.exepath("mojo-lsp-server") == "" then
    vim.notify("mojo-lsp-server not found in PATH", vim.log.levels.ERROR)
    return
  end
  lspconfig.mojo.setup(vim.tbl_deep_extend("force", {
    on_attach = opts.on_attach or function(_, bufnr)
      local function map(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc, noremap = true, silent = true })
      end
      map("gd", vim.lsp.buf.definition,  "Go to definition")
      map("K",  vim.lsp.buf.hover,       "Hover documentation")
    end,
    capabilities = opts.capabilities or (function()
      local ok_cmp, cmp = pcall(require, "cmp_nvim_lsp")
      return ok_cmp and cmp.default_capabilities() or vim.lsp.protocol.make_client_capabilities()
    end)(),
    single_file_support = true,
  }, opts.mojo_settings or {}))
end
function Config.setup_completion(opts)
  opts = opts or {}
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "mojo", "🔥" },
    callback = function()
      vim.bo.omnifunc = "v:lua.vim.lsp.omnifunc"
      for k, v in pairs(opts.completion_settings or {}) do
        vim.opt_local[k] = v
      end
    end,
  })
end
function Config.setup_diagnostics(opts)
  vim.diagnostic.config(vim.tbl_extend("force", {
    virtual_text    = true,
    signs           = true,
    underline       = true,
    update_in_insert= false,
    severity_sort   = true,
    float           = { border = "rounded", source = "if_many" },
  }, opts or {}))
end
function Config.setup_keymaps(opts)
  opts = opts or {}
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "mojo", "🔥" },
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      local function map(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, { buffer = buf, desc = desc, noremap = true, silent = true })
      end
      map(opts.format_keymap or "<leader>f", function()
        local ok_c, conform = pcall(require, "conform")
        if ok_c then
          conform.format({ bufnr = buf })
        else
          vim.lsp.buf.format({ bufnr = buf })
        end
      end, "Format file")
      if opts.lsp_keymaps ~= false then
        map("gd", vim.lsp.buf.definition,  "Definition")
        map("gD", vim.lsp.buf.declaration, "Declaration")
        map("gr", vim.lsp.buf.references,  "References")
        map("K",  vim.lsp.buf.hover,       "Hover")
        map("<leader>rn", vim.lsp.buf.rename,       "Rename symbol")
        map("<leader>ca", vim.lsp.buf.code_action,  "Code actions")
      end
      for lhs, rhs in pairs(opts.custom_keymaps or {}) do
        map(lhs, rhs, "")
      end
    end,
  })
end
function Config.setup_filetype(opts)
  opts = opts or {}
  vim.filetype.add({
    extension = { mojo = "mojo", ["🔥"] = "mojo" },
    filename  = opts.filename_patterns or {},
    pattern   = opts.file_patterns    or {},
  })
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "mojo", "🔥" },
    callback = function()
      local defaults = {
        tabstop     = 4,
        shiftwidth  = 4,
        expandtab   = true,
        autoindent  = true,
        smartindent = true,
      }
      for k, v in pairs(vim.tbl_deep_extend("force", defaults, opts.buffer_options or {})) do
        vim.opt_local[k] = v
      end
    end,
  })
end
function Config.setup(user_opts)
  user_opts = user_opts or {}

  Config.setup_filetype  (user_opts.filetype   )
  if user_opts.ts         ~= false then Config.setup_ts        (user_opts.ts        ) end
  if user_opts.conform    ~= false then Config.setup_conform   (user_opts.conform   ) end
  if user_opts.lsp        ~= false then Config.setup_lsp       (user_opts.lsp       ) end
  if user_opts.completion ~= false then Config.setup_completion(user_opts.completion) end
  if user_opts.diagnostics~= false then Config.setup_diagnostics(user_opts.diagnostics) end
  if user_opts.keymaps    ~= false then Config.setup_keymaps   (user_opts.keymaps   ) end
  vim.notify("blaze-ts.nvim configured", vim.log.levels.DEBUG)
end
return Config
