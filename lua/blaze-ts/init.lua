-- blaze-ts.nvim/lua/blaze-ts/init.lua
-- ------------------------------------
-- luacheck: globals vim
-- The entry‑point that wires the mojo ⇄ Neovim integration together.
-- Pure‑Lua, declarative, and compatible with both Neovim ≥ 0.12‑dev and 0.9.

local Init = {}

local function join(...) return table.concat({ ... }, package.config:sub(1, 1)) end
local function is_readable(path) return vim.fn.filereadable(path) == 1 end

local function add_ts_language(lang, spec)
  local ok_lang, ts_lang = pcall(require, "vim.treesitter.language")
  if ok_lang and (ts_lang.add or ts_lang.register) then
    (ts_lang.add or ts_lang.register)(lang, spec)
    return true
  end
  local ok_parsers, parsers = pcall(require, "nvim-treesitter.parsers")
  if ok_parsers then
    local cfg = parsers.get_parser_configs()[lang] or {}
    cfg.install_info = cfg.install_info or {}
    cfg.install_info.url = "local"
    cfg.install_info.files = {}
    cfg.path = spec.path
    cfg.filetype = spec.filetypes[1]
    parsers.get_parser_configs()[lang] = cfg
    return true
  end
  return false
end

---@param opts table|nil
function Init.setup(opts)
  opts = opts or {}

  local script_dir = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])") or "./"
  local parser_dir = opts.parser_dir or join(script_dir, "parsers")

  local filetypes = { "mojo", "🔥" }
  local native_path = join(parser_dir, "mojo.so")
  if is_readable(native_path) then
    add_ts_language("mojo", { path = native_path, filetypes = filetypes })
  end
  local wasm_path = join(parser_dir, "mojo.wasm")
  if is_readable(wasm_path) then
    add_ts_language("mojo-wasm", { path = wasm_path, filetypes = filetypes })
  end
  local ok_lang, ts_lang = pcall(require, "vim.treesitter.language")
  if ok_lang and ts_lang.register then
    ts_lang.register("mojo", filetypes)
  end
  vim.filetype.add({
    extension = { mojo = "mojo", ["🔥"] = "mojo" },
  })
  vim.notify("blaze‑ts.nvim initialised", vim.log.levels.DEBUG)
end
return Init
