-- blaze-ts.nvim/lazy.lua
return {
  "qompassai/blaze-ts.nvim",
  lazy = true,
  ft = { "mojo", "🔥" },
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
  opts = {
    parser = {
      auto_install = true,
    },
    nvim_treesitter = {
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
      parser_config = {
        mojo = {
          install_info = {
            url = "https://github.com/qompassai/blaze-ts.nvim",
            files = { "src/parser.c", "src/grammar.js", "src/main.zig", "src/root.zig", "src/scanner.c" },
            branch = "main",
            requires_generate_from_grammar = false,
          },
          filetype = { "mojo", "🔥" },
          maintainers = { "@qompassai" },
        },
      },
    },
  },
  config = function(_, opts)
    local success, error_msg = pcall(function()
      local ts_success, ts_config = pcall(require, "nvim-treesitter.configs")
      if not ts_success then
        vim.notify("nvim-treesitter not available", vim.log.levels.WARN)
        return
      end
      if opts.nvim_treesitter and opts.nvim_treesitter.parser_config then
        local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
        for name, config in pairs(opts.nvim_treesitter.parser_config) do
          parser_config[name] = config
        end
      end
      ts_config.setup(opts.nvim_treesitter or {})
      require("blaze-ts").setup(opts)
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
