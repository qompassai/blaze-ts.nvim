local Loader = {}

---@return string Operating‑system name: linux | darwin | windows
local function os_name()
  return require("blaze-ts.utils").get_os_name()
end

---@return string Shared‑library extension (.so / .dylib / .dll)
local function lib_ext()
  local os = os_name()
  if os == "linux" then return "so" end
  if os == "darwin" then return "dylib" end
  return "dll"
end

---@return string 
local function build_path()
  local src = debug.getinfo(1, "S").source:sub(2)
  local dir = vim.fn.fnamemodify(src, ":p:h")
  return dir .. "/../build/?." .. lib_ext()
end

function Loader.load()
  local path = build_path()
  if not package.cpath:find(path, 1, true) then
    package.cpath = package.cpath:gsub(";$", "") .. ";" .. path
  end
end

return Loader
