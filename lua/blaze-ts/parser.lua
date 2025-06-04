-- blaze-ts.nvim/lua/blaze-ts/parser.lua
-- -------------------------------------
-- luacheck: globals vim

local Parser = {}

local sep = package.config:sub(1, 1)
local function join(...) return table.concat({ ... }, sep) end
local function script_dir()
  return debug.getinfo(1, "S").source:sub(2):match(".*/") or "./"
end

local function candidate_paths()
  local data = vim.fn.stdpath("data")
  return {
    join(data, "lazy", "nvim-treesitter", "parser", "mojo.so"),
    join(data, "site", "parser", "mojo.so"),
    vim.fn.expand("~/.local/share/nvim/site/parser/mojo.so"),
    join(script_dir(), "../parser", "mojo.so"),
  }
end

function Parser.get_parser_path()
  for _, p in ipairs(candidate_paths()) do
    if vim.fn.filereadable(p) == 1 then return p end
  end
end

local function register_config()
  local ok, parsers = pcall(require, "nvim-treesitter.parsers")
  if not ok then return false end
  local cfgs = parsers.get_parser_configs()
  if cfgs.mojo then return true end
  cfgs.mojo = {
    install_info = {
      url = "https://github.com/qompassai/blaze-ts.nvim",
      files = { "src/parser.c", "src/scanner.c" },
      branch = "main",
      requires_generate_from_grammar = false,
    },
    filetype = { "mojo", "🔥" },
  }
  return true
end

function Parser.install()
  if not register_config() then return false end
  local ok, install = pcall(require, "nvim-treesitter.install")
  if not ok then return false end
  if install.is_installed("mojo") then return true end
  vim.notify("Installing Mojo parser…", vim.log.levels.INFO)
  local ok2, res = pcall(install.install_parsers, { "mojo" })
  if ok2 then vim.notify("Mojo parser installed", vim.log.levels.INFO) end
  return ok2 and res
end

function Parser.setup_runtime_path()
  local runtime = join(script_dir(), "../../runtime")
  if vim.fn.isdirectory(runtime) == 1 and not vim.tbl_contains(vim.opt.rtp:get(), runtime) then
    vim.opt.rtp:prepend(runtime)
  end
end

function Parser.health()
  local status = {
    config     = register_config(),
    path       = Parser.get_parser_path(),
  }
  status.installed = status.path ~= nil
  status.loadable = pcall(function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].filetype = "mojo"
    local ok = pcall(vim.treesitter.get_parser, buf, "mojo")
    vim.api.nvim_buf_delete(buf, { force = true })
    return ok
  end)
  return status
end

return Parser
