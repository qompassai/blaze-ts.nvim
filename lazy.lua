-- blaze-ts.nvim/lazy.lua
return {
  "qompassai/blaze-ts.nvim",
  lazy = true,
  ft = { "mojo", "🔥" },
  build = function()
    vim.cmd("TSUpdate")
    pcall(vim.cmd, "TSInstall mojo")
  end,
  dependencies = {
    {
      "williamboman/mason.nvim",
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    "nvim-treesitter/nvim-treesitter",
    "neovim/nvim-lspconfig",
    "stevearc/conform.nvim",
    {
      "hrsh7th/nvim-cmp",
      optional = true,
    },
    {
      "L3MON4D3/LuaSnip",
      optional = true,
    },
  },
  cmd = {
    "BlazeHealth",
    "BlazeParserHealth",
    "BlazeReinstallParser",
    "TSInstall mojo",
  },
  config = function(_, opts)
    local success, error_msg = pcall(function()
      local ts_success, ts_config = pcall(require, "nvim-treesitter.configs")
      if ts_success then
        ts_config.setup({
          highlight = {
            enable = true,
            additional_vim_regex_highlighting = false,
          },
          indent = { enable = true },
          incremental_selection = {
            enable = true,
            keymaps = {
              init_selection = "<C-space>",
              node_incremental = "<C-space>",
              node_decremental = "<bs>",
            },
          },
          modules = {},
          sync_install = false,
          ensure_installed = {
            "lua",
            "vim",
            "vimdoc",
            "query",
            "mojo",
            "python",
            "toml",
            "dockerfile",
            "bash",
            "json",
            "markdown",
            "yaml",
            "javascript",
            "typescript",
            "html",
            "css",
          },
          ignore_install = {},
          auto_install = true,
        })
      else
        vim.notify("nvim-treesitter not available", vim.log.levels.WARN)
      end

      local blaze_opts = vim.tbl_deep_extend("force", {
        lsp = {
          on_attach = function(client, bufnr)
            local opts = { buffer = bufnr, silent = true }
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
            vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
            vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
            vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
          end,
          capabilities = vim.lsp.protocol.make_client_capabilities(),
        },
        config = {
          format_on_save = {
            timeout_ms = 500,
            lsp_fallback = true,
          },
          line_length = 88,
          indent_width = 4,
        },
      }, opts or {})

      require("blaze-ts").setup(blaze_opts)
    end)

    if not success then
      vim.notify("Failed to setup blaze-ts.nvim: " .. tostring(error_msg), vim.log.levels.ERROR)
    else
      vim.notify("blaze-ts.nvim loaded successfully", vim.log.levels.INFO)
    end
  end,

  init = function()
    vim.filetype.add({
      extension = {
        mojo = "mojo",
        ["🔥"] = "mojo",
      },
    })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "mojo", "🔥" },
      callback = function()
        vim.opt_local.tabstop = 4
        vim.opt_local.shiftwidth = 4
        vim.opt_local.expandtab = true
        vim.opt_local.autoindent = true
        vim.opt_local.smartindent = true
        vim.opt_local.commentstring = "# %s"
      end,
    })
  end,

  keys = {
    {
      "<leader>mf",
      function()
        local conform = pcall(require, "conform")
        if conform then
          require("conform").format({ bufnr = 0 })
        else
          vim.lsp.buf.format()
        end
      end,
      desc = "Format Mojo file",
      ft = { "mojo", "🔥" },
    },
    {
      "<leader>mh",
      function()
        require("blaze-ts").health_check()
      end,
      desc = "Blaze-TS health check",
    },
    {
      "<leader>mp",
      function()
        require("blaze-ts").parser_health()
      end,
      desc = "Mojo parser health",
    },
  },
}
