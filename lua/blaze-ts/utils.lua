-- blaze-ts.nvim/lua/blaze-ts/utils.lua
-- ------------------------------------
-- luacheck: globals vim

local U = {}
local sep = package.config:sub(1, 1)
local function join(...) return table.concat({ ... }, sep) end
local function stat(path) return path and vim.loop.fs_stat(path) or nil end
function U.file_exists(p) return stat(p) and stat(p).type == "file" end
function U.dir_exists(p)  return stat(p) and stat(p).type == "directory" end
local function uname() return (vim.loop.os_uname() or {}).sysname or "unknown" end
function U.get_os_name() return uname():lower() end
function U.is_linux()    return U.get_os_name() == "linux"   end
function U.is_macos()    return U.get_os_name() == "darwin"  end
function U.is_windows()  return U.get_os_name():match("windows") ~= nil end
function U.find_up(target, start)
  local path = vim.fn.expand(start or vim.fn.getcwd())
  local root = U.is_windows() and "C:\\" or "/"
  while path and path ~= root do
    local candidate = join(path, target)
    if U.file_exists(candidate) or U.dir_exists(candidate) then return candidate end
    path = vim.fn.fnamemodify(path, ":h")
  end
end
local function parser_ext()
  local os = U.get_os_name()
  return os == "darwin" and "dylib" or (os:match("windows") and "dll" or "so")
end
function U.load_parser_library()
  local src   = debug.getinfo(1, "S").source:sub(2)
  local lib   = join(vim.fn.fnamemodify(src, ":h"), "..", "parser", "?." .. parser_ext())
  if not package.cpath:find(lib, 1, true) then package.cpath = package.cpath .. ";" .. lib end
  return lib
end
function U.setup_ts_runtime_path()
  local rtp = join(vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h:h"), "runtime")
  if not U.dir_exists(rtp) then return end
  if not vim.tbl_contains(vim.opt.rtp:get(), rtp) then vim.opt.rtp:prepend(rtp) end
  return rtp
end
local function exec(cmd)
  local ok, handle = pcall(io.popen, cmd .. " 2>/dev/null")
  if not ok or not handle then return end
  local out = handle:read("*a") handle:close() return out
end
local function mojo_env()
  local has_modular = vim.fn.executable("modular") == 1
  return {
    has_mojo    = vim.fn.executable("mojo") == 1,
    has_modular = has_modular,
    has_pixi    = vim.fn.executable("pixi") == 1,
    has_docker  = vim.fn.executable("docker") == 1,
    mojo_path   = has_modular and exec("modular config mojo.path") or nil,
    has_max     = has_modular and (exec("modular max list") or ""):match("max%-driver") ~= nil,
    pixi_project= U.find_up("pixi.toml") ~= nil,
    in_docker   = U.file_exists("/.dockerenv"),
  }
end
local function gpu_env()
  local gpu = { has_nvidia = false, has_amd = false, has_intel = false }
  local smi = exec("nvidia-smi --query-gpu=count,driver_version --format=csv,noheader")
  if smi and #smi > 0 then
    gpu.has_nvidia    = true
    gpu.gpu_count     = tonumber(smi:match("^(%d+)") or "0")
    gpu.driver_version= smi:match(",%s*([^,\n]+)$")
    local nvcc        = exec("nvcc --version")
    gpu.cuda_version  = nvcc and nvcc:match("release%s+([%d%.]+)") or nil
  end
  local rocm = exec("rocm-smi --showproductname")
  if rocm and rocm:match("GPU%[") then
    gpu.has_amd = true
    gpu.rocm_version = (exec("rocm-smi --showversion") or ""):match("ROCm Version:%s+([%d%.]+)")
  end
  gpu.has_intel = (exec("lspci | grep -i 'VGA\\|3D\\|Display' | grep -i intel") or ""):len() > 0
  return gpu
end
local function pixi_env()
  if vim.fn.executable("pixi") == 0 then return { has_pixi = false } end
  local toml = U.find_up("pixi.toml")
  if not toml then return { has_pixi = true } end
  local root = vim.fn.fnamemodify(toml, ":h")
  local info = exec("pixi info") or ""
  local env  = info:match("Environment path:%s+([%S]+)")
  local bin  = env and join(env, "bin")
  return {
    has_pixi     = true,
    project_root = root,
    env_path     = env,
    bin_path     = U.dir_exists(bin) and bin or vim.fn.exepath("pixi"),
  }
end
local function magic_docker()
  local cfg = U.find_up(".magic.docker")
  if not cfg or not U.file_exists(cfg) then return { enabled = false } end
  local content = (io.open(cfg):read("*a")) or ""
  return {
    enabled      = true,
    config_path  = cfg,
    image        = content:match('IMAGE="([^"]+)"') or content:match("IMAGE='([^']+)'"),
  }
end
function U.detect_environment()
  local mojo  = mojo_env()
  return {
    mojo  = mojo,
    pixi  = pixi_env(),
    gpu   = gpu_env(),
    docker= { has_docker = mojo.has_docker, magic = magic_docker() },
    system= { os = U.get_os_name(), is_linux = U.is_linux(), is_macos = U.is_macos(), is_windows = U.is_windows() },
  }
end
function U.setup()
  U.load_parser_library()
  U.setup_ts_runtime_path()
  return U.detect_environment()
end
function U.health()
  local env = U.detect_environment()
  local ok  = {}
  local warn= {}
  if not env.mojo.has_mojo then table.insert(warn, "Mojo compiler not found") end
  if env.pixi.has_pixi then table.insert(ok, "Pixi detected") end
  if env.gpu.has_nvidia then table.insert(ok, "NVIDIA GPU") end
  if #warn > 0 then vim.notify(table.concat(warn, "; "), vim.log.levels.WARN) end
  return { ok = ok, warn = warn }
end
return U
