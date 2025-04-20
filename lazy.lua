--blaze-ts.nvim/lazy.lua
return {
  "qompassai/blaze-ts.nvim",
  lazy = true,
  ft = { "mojo", "🔥" },
  build = ":TSUpdate",
  dependencies = {
    {
      "williamboman/mason.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim"
  },
    "nvim-treesitter/nvim-treesitter",
  },
  config = function(_, opts)
  require("nvim-treesitter.configs").setup({
    highlight = { enable = true },
    indent = { enable = true },
    modules = {},
    sync_install = false,
    ensure_installed = {
      "lua", "vim", "vimdoc", "query", "mojo", "python", "toml", "dockerfile", "bash", "json", "markdown"
    },
    ignore_install = {},
    auto_install = true,
  })
  require("blaze-ts.nvim").setup(opts)
  end
}
