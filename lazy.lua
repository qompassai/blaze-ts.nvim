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
    "nvim-treesitter/nvim-treesitter",
    "nvim-lua/plenary.nvim",
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
        local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
        parser_config.mojo = {
          install_info = {
            url = "https://github.com/qompassai/blaze-ts.nvim",
            files = { "src/parser.c", "src/grammar.js", "src/scanner.c", "main.zig", "root.zig" },
            branch = "main",
            requires_generate_from_grammar = true,
          },
          filetype = { "mojo", "🔥" },
          maintainers = { "@qompassai" },
        }
        ts_config.setup({
          ensure_installed = { "mojo" },
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
        })
      else
        vim.notify("nvim-treesitter not available", vim.log.levels.WARN)
      end

      local blaze_ts_opts = vim.tbl_deep_extend("force", {
        parser = {
          install_dir = vim.fn.stdpath("data") .. "/lazy/blaze-ts.nvim",
          auto_install = true,
        },
      }, opts or {})

      require("blaze-ts").setup(blaze_ts_opts)
    end)

    if not success then
      vim.notify("Failed to setup blaze-ts.nvim: " .. tostring(error_msg), vim.log.levels.ERROR)
    end
  end,

  keys = {
    {
      "<leader>mh",
      function()
        require("blaze-ts").health_check()
      end,
      desc = "Blaze-TS health check",
      ft = { "mojo", "🔥" },
    },
    {
      "<leader>mp", 
      function()
        require("blaze-ts").parser_health()
      end,
      desc = "Mojo parser health",
      ft = { "mojo", "🔥" },
    },
    {
      "<leader>mr",
      function()
        vim.cmd("BlazeReinstallParser")
      end,
      desc = "Reinstall Mojo parser",
      ft = { "mojo", "🔥" },
    },
  },
}

