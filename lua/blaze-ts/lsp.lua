--blaze-ts.nvim/lua/blaze-ts/lsp.lua
------------------------------------
local M = {}
---
function M.setup_lsp(opts)
  opts = opts or {}
  ---
  local has_nightly = vim.fn.has("nvim-0.11") == 1
  ---
  local default_settings = {
    cmd = opts.cmd or { "mojo-lsp-server" },
    filetypes = opts.filetypes or { "mojo", "🔥" },
    single_file_support = true,
    root_dir = function(fname)
      return vim.fs.dirname(vim.fs.find({ ".git", "pixi.toml", "pyproject.toml" }, { path = fname, upward = true })[1])
    end,
    settings = opts.settings or {
      mojo = {
        inlayHints = opts.inlay_hints or { enable = true },
        completion = opts.completion or { snippets = true },
      },
    },
    on_attach = opts.on_attach,
    capabilities = opts.capabilities,
  }

  if has_nightly then
    vim.lsp.config("mojo", {
      cmd = default_settings.cmd,
      filetypes = default_settings.filetypes,
      root_markers = { ".git", "pixi.toml", "pyproject.toml" },
      settings = default_settings.settings,
    })
  else
    local has_lspconfig, lspconfig = pcall(require, "lspconfig")
    if has_lspconfig then
      if lspconfig.mojo then
      else
        local configs = require("lspconfig.configs")
        if not configs.mojo then
          configs.mojo = {
            default_config = {
              cmd = default_settings.cmd,
              filetypes = default_settings.filetypes,
              root_dir = default_settings.root_dir,
              single_file_support = default_settings.single_file_support,
              settings = default_settings.settings,
            },
            docs = {
              description = [[
https://github.com/modularml/mojo

`mojo-lsp-server` can be installed [via Modular](https://developer.modular.com/download)

Mojo is a new programming language that bridges the gap between research and production by combining Python syntax and ecosystem with systems programming and metaprogramming features.
]],
            },
          }
        end
        lspconfig.mojo.setup(default_settings)
      end
    else
      vim.api.nvim_create_autocmd("FileType", {
        pattern = default_settings.filetypes,
        callback = function()
          local root_dir = vim.fs.dirname(vim.fs.find({ ".git", "pixi.toml", "pyproject.toml" }, { upward = true })[1]) or vim.fn.getcwd()
          local client = vim.lsp.start({
            name = "mojo",
            cmd = default_settings.cmd,
            root_dir = root_dir,
            settings = default_settings.settings,
          })
          if client then
            vim.lsp.buf_attach_client(0, client)
            if default_settings.on_attach then
              default_settings.on_attach(client, 0)
            end
          end
        end,
      })
    end
  end
  ---
end
return M
