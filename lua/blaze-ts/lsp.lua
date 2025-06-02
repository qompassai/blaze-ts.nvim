-- blaze-ts.nvim/lua/blaze-ts/lsp.lua
------------------------------------
local M = {}

function M.setup(opts)
  opts = opts or {}

  if vim.fn.executable("mojo-lsp-server") == 0 then
    vim.notify("mojo-lsp-server not found, skipping LSP setup", vim.log.levels.WARN)
    return
  end

  local has_nightly = vim.fn.has("nvim-0.11") == 1

  local default_settings = {
    cmd = opts.cmd or { "mojo-lsp-server" },
    filetypes = opts.filetypes or { "mojo", "🔥" },
    single_file_support = true,
    root_dir = function(fname)
      local found = vim.fs.find({ ".git", "pixi.toml", "pyproject.toml" }, { path = fname, upward = true })
      if found and #found > 0 then
        return vim.fs.dirname(found[1])
      end
      return vim.fn.getcwd()
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
    local config_success, config_error = pcall(function()
      if vim.lsp.config then
        vim.lsp.config("mojo", {
          cmd = default_settings.cmd,
          filetypes = default_settings.filetypes,
          root_markers = { ".git", "pixi.toml", "pyproject.toml" },
          settings = default_settings.settings,
        })
        vim.notify("Mojo LSP configured using nightly API", vim.log.levels.INFO)
      else
        error("vim.lsp.config not available")
      end
    end)

    if not config_success then
      vim.notify("Nightly LSP config failed: " .. tostring(config_error), vim.log.levels.WARN)
      has_nightly = false -- Fallback to legacy method
    end
  end

  if not has_nightly then
    local has_lspconfig, lspconfig = pcall(require, "lspconfig")
    if has_lspconfig then
      M.setup_with_lspconfig(lspconfig, default_settings)
    else
      M.setup_manual(default_settings)
    end
  end
end

function M.setup_with_lspconfig(lspconfig, default_settings)
  local setup_success, setup_error = pcall(function()
    if lspconfig.mojo then
      lspconfig.mojo.setup(default_settings)
      vim.notify("Mojo LSP configured using existing lspconfig", vim.log.levels.INFO)
    else
      local configs_success, configs = pcall(require, "lspconfig.configs")
      if configs_success then
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
        vim.notify("Mojo LSP configured using new lspconfig", vim.log.levels.INFO)
      else
        error("Could not access lspconfig.configs")
      end
    end
  end)

  if not setup_success then
    vim.notify("lspconfig setup failed: " .. tostring(setup_error), vim.log.levels.WARN)
    M.setup_manual(default_settings)
  end
end

function M.setup_manual(default_settings)
  vim.api.nvim_create_autocmd("FileType", {
    pattern = default_settings.filetypes,
    callback = function()
      local found = vim.fs.find({ ".git", "pixi.toml", "pyproject.toml" }, { upward = true })
      local root_dir = (found and #found > 0) and vim.fs.dirname(found[1]) or vim.fn.getcwd()

      local start_success, client = pcall(vim.lsp.start, {
        name = "mojo",
        cmd = default_settings.cmd,
        root_dir = root_dir,
        settings = default_settings.settings,
      })

      if start_success and client then
        local attach_success, attach_error = pcall(vim.lsp.buf_attach_client, 0, client)
        if attach_success then
          if default_settings.on_attach then
            local on_attach_success, on_attach_error = pcall(default_settings.on_attach, client, 0)
            if not on_attach_success then
              vim.notify("on_attach callback failed: " .. tostring(on_attach_error), vim.log.levels.WARN)
            end
          end
          vim.notify("Mojo LSP attached manually", vim.log.levels.INFO)
        else
          vim.notify("Failed to attach LSP client: " .. tostring(attach_error), vim.log.levels.ERROR)
        end
      else
        vim.notify("Failed to start LSP client: " .. tostring(client), vim.log.levels.ERROR)
      end
    end,
  })
end

function M.health()
  local health = {
    lsp_server_available = vim.fn.executable("mojo-lsp-server") == 1,
    lspconfig_available = pcall(require, "lspconfig"),
    nightly_api_available = vim.fn.has("nvim-0.11") == 1 and vim.lsp.config ~= nil,
  }

  print("Mojo LSP Health:")
  print("================")
  for key, value in pairs(health) do
    print(key .. ": " .. tostring(value))
  end

  return health
end

function M.setup_lsp(opts)
  vim.notify("setup_lsp is deprecated, use setup instead", vim.log.levels.WARN)
  return M.setup(opts)
end

return M
