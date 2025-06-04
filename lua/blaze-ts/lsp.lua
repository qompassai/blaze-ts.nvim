-- blaze-ts.nvim/lua/blaze-ts/lsp.lua
-- ----------------------------------
-- luacheck: globals vim

local Lsp = {}
local function default(val, fallback) return val == nil and fallback or val end
local function root_pattern()
  return function(fname)
    local root = vim.fs.find({
      ".git",
      "modular.yaml",
      "pixi.toml",
      "pyproject.toml",
    }, { path = fname, upward = true })[1]
    return root and vim.fs.dirname(root) or vim.fn.getcwd()
  end
end
local function compute_capabilities(user_capabilities)
  if user_capabilities then return user_capabilities end
  local ok_cmp, cmp = pcall(require, "cmp_nvim_lsp")
  return ok_cmp and cmp.default_capabilities() or vim.lsp.protocol.make_client_capabilities()
end
---@param user_opts table|nil
function Lsp.setup(user_opts)
  if vim.fn.executable("mojo-lsp-server") == 0 then
    vim.notify("mojo‑lsp‑server not found; skipping Mojo LSP", vim.log.levels.WARN)
    return
  end
  local opts = user_opts or {}
  local settings = opts.settings or {
    mojo = {
      inlayHints = default(opts.inlay_hints, { enable = true }),
      completion = default(opts.completion,  { snippets = true }),
    },
  }
  local base_cfg = {
    cmd                 = opts.cmd or { "mojo-lsp-server" },
    filetypes           = opts.filetypes or { "mojo", "🔥" },
    single_file_support = true,
    root_dir            = opts.root_dir or root_pattern(),
    settings            = settings,
    on_attach           = opts.on_attach,
    capabilities        = compute_capabilities(opts.capabilities),
  }
  local ok_lsp, lspconfig = pcall(require, "lspconfig")
  if ok_lsp then
    local cfgs = require("lspconfig.configs")
    if not cfgs.mojo then cfgs.mojo = { default_config = base_cfg } end
    lspconfig.mojo.setup(base_cfg)
    vim.notify("Mojo LSP configured via lspconfig", vim.log.levels.INFO)
    return
  end

  vim.api.nvim_create_autocmd("FileType", {
    pattern = base_cfg.filetypes,
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      local cfg = vim.tbl_extend("keep", {
        name     = "mojo",
        root_dir = base_cfg.root_dir(vim.api.nvim_buf_get_name(buf)),
      }, base_cfg)
      local started, client = pcall(vim.lsp.start, cfg)
      if not started then
        vim.notify("Failed to start Mojo LSP: " .. tostring(client), vim.log.levels.ERROR)
        return
      end
      if base_cfg.on_attach then
        pcall(base_cfg.on_attach, client, buf)
      end
      vim.notify("Mojo LSP attached (manual)", vim.log.levels.DEBUG)
    end,
  })
end
return Lsp
