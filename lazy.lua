return {
  "qompassai/blaze-ts.nvim",
  lazy = true,
  ft   = { "mojo", "🔥" },
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

  ---@type table
  opts = {
    parser = { auto_install = true },
    nvim_treesitter = {
      ensure_installed = { "mojo" },
      highlight = { enable = true, additional_vim_regex_highlighting = false },
      indent    = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection    = "<C-space>",
          node_incremental  = "<C-space>",
          node_decremental  = "<BS>",
        },
      },
      parser_config = {
        mojo = {
          install_info = {
            url   = "https://github.com/qompassai/blaze-ts.nvim",
            files = {
              "src/parser.c",
              "src/grammar.js",
              "src/main.zig",
              "src/root.zig",
              "src/scanner.c",
            },
            branch = "main",
            requires_generate_from_grammar = false,
          },
          filetype    = { "mojo", "🔥" },
          maintainers = { "@qompassai" },
        },
      },
    },
  },

  config = function(_, opts)
    local ok, treesitter = pcall(require, "nvim-treesitter.configs")
    if not ok then
      vim.notify("nvim-treesitter not available", vim.log.levels.WARN)
      return
    end

    if opts.nvim_treesitter and opts.nvim_treesitter.parser_config then
      local pcfg = require("nvim-treesitter.parsers").get_parser_configs()
      for lang, cfg in pairs(opts.nvim_treesitter.parser_config) do
        pcfg[lang] = cfg
      end
    end
    treesitter.setup(opts.nvim_treesitter or {})
    require("blaze-ts").setup(opts)
  end,

  keys = {
    {
      "<leader>mh",
      function() require("blaze-ts").health_check() end,
      desc = "Blaze‑TS health check",
      ft   = { "mojo", "🔥" },
    },
    {
      "<leader>mp",
      function() require("blaze-ts").parser_health() end,
      desc = "Mojo parser health",
      ft   = { "mojo", "🔥" },
    },
    {
      "<leader>mr",
      function() vim.cmd("BlazeReinstallParser") end,
      desc = "Reinstall Mojo parser",
      ft   = { "mojo", "🔥" },
    },
  },
}
