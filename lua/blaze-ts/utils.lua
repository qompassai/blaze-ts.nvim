---/blaze-ts.nvim/lua/blaze-ts/utils.lua
----------------------------------------
local M = {}

function M.get_os_name()
  local success, os_info = pcall(vim.loop.os_uname)
  if success and os_info then
    return os_info.sysname:lower()
  end
  return "unknown"
end

function M.is_linux()
  return M.get_os_name() == "linux"
end

function M.is_macos()
  return M.get_os_name() == "darwin"
end

function M.is_windows()
  return M.get_os_name():match("windows") ~= nil
end

function M.file_exists(path)
  if not path then
    return false
  end
  local success, stat = pcall(vim.loop.fs_stat, path)
  return success and stat and stat.type == "file"
end

function M.dir_exists(path)
  if not path then
    return false
  end
  local success, stat = pcall(vim.loop.fs_stat, path)
  return success and stat and stat.type == "directory"
end

function M.find_up(name, start_path)
  start_path = vim.fn.expand(start_path or vim.fn.getcwd())
  local path = start_path
  local root = M.is_windows() and "C:\\" or "/"

  while path ~= root do
    local check_path = path .. "/" .. name
    if M.file_exists(check_path) or M.dir_exists(check_path) then
      return check_path
    end
    path = vim.fn.fnamemodify(path, ":h")
  end
  return nil
end

function M.get_library_path()
  local os_name = M.get_os_name()
  local ext = "so"
  if os_name == "darwin" then
    ext = "dylib"
  elseif os_name:match("windows") then
    ext = "dll"
  end

  local source = debug.getinfo(1).source
  if source:sub(1, 1) == "@" then
    source = source:sub(2)
  end

  local dirname = vim.fn.fnamemodify(source, ":p:h")
  return dirname .. ("/../parser/?.%s"):format(ext)
end

function M.load_parser_library()
  local library_path = M.get_library_path()
  if library_path and not string.find(package.cpath, library_path, 1, true) then
    local trim_semicolon = function(s)
      return s:sub(-1) == ";" and s:sub(1, -2) or s
    end
    package.cpath = trim_semicolon(package.cpath) .. ";" .. library_path
  end
  return library_path
end

function M.setup_ts_runtime_path()
  local source = debug.getinfo(1).source
  if source:sub(1, 1) == "@" then
    source = source:sub(2)
  end

  local runtime_path = vim.fn.fnamemodify(source, ":p:h:h:h") .. "/runtime"
  if M.dir_exists(runtime_path) then
    local success, rtp = pcall(vim.opt.rtp.get, vim.opt.rtp)
    if success and rtp then
      if type(rtp) == "table" then
        if not vim.tbl_contains(rtp, runtime_path) then
          vim.opt.rtp:prepend(runtime_path)
        end
      else
        vim.opt.rtp:prepend(runtime_path)
      end
    end
  end
  return runtime_path
end

function M.detect_mojo_env()
  local env = {
    has_mojo = vim.fn.executable("mojo") == 1,
    has_modular = vim.fn.executable("modular") == 1,
    has_pixi = vim.fn.executable("pixi") == 1,
    has_docker = vim.fn.executable("docker") == 1,
    modular_path = vim.fn.expand("~/.modular"),
    pixi_project = M.find_up("pixi.toml") ~= nil,
    in_docker = M.file_exists("/.dockerenv"),
    mojo_path = nil,
    has_max = false,
  }

  if env.has_modular then
    local success, handle = pcall(io.popen, "modular config mojo.path 2>/dev/null")
    if success and handle then
      env.mojo_path = handle:read("*l")
      handle:close()
    end
  end

  if env.has_modular then
    local success, handle = pcall(io.popen, "modular max list 2>/dev/null")
    if success and handle then
      local output = handle:read("*a")
      handle:close()
      env.has_max = output and output:match("max%-driver") ~= nil
    end
  end

  return env
end

function M.detect_gpu()
  local gpu = {
    has_nvidia = false,
    has_amd = false,
    has_intel = false,
    cuda_version = nil,
    rocm_version = nil,
    gpu_count = 0,
    driver_version = nil,
  }

  local success, nvidia_smi = pcall(io.popen, "nvidia-smi --query-gpu=count,name,driver_version --format=csv,noheader 2>/dev/null")
  if success and nvidia_smi then
    local output = nvidia_smi:read("*a")
    nvidia_smi:close()
    if output and #output > 0 then
      gpu.has_nvidia = true
      gpu.gpu_count = tonumber(output:match("^%s*(%d+)") or "0")
      gpu.driver_version = output:match(",%s*([^,\n]+)$")

      local cuda_success, cuda_version = pcall(io.popen, "nvcc --version 2>/dev/null")
      if cuda_success and cuda_version then
        local cuda_output = cuda_version:read("*a")
        cuda_version:close()
        gpu.cuda_version = cuda_output and cuda_output:match("release%s+(%d+%.%d+)")
      end
    end
  end

  local rocm_success, rocm_smi = pcall(io.popen, "rocm-smi --showproductname 2>/dev/null")
  if rocm_success and rocm_smi then
    local output = rocm_smi:read("*a")
    rocm_smi:close()
    if output and output:match("GPU%[") then
      gpu.has_amd = true

      local version_success, rocm_version = pcall(io.popen, "rocm-smi --showversion 2>/dev/null")
      if version_success and rocm_version then
        local version_output = rocm_version:read("*a")
        rocm_version:close()
        gpu.rocm_version = version_output and version_output:match("ROCm Version:%s+(%d+%.%d+)")
      end
    end
  end

  local intel_success, intel_gpu = pcall(io.popen, "lspci | grep -i 'VGA\\|3D\\|Display' | grep -i intel 2>/dev/null")
  if intel_success and intel_gpu then
    local output = intel_gpu:read("*a")
    intel_gpu:close()
    gpu.has_intel = output and #output > 0
  end

  return gpu
end

function M.setup_pixi_env()
  local pixi_env = {
    has_pixi = vim.fn.executable("pixi") == 1,
    project_root = nil,
    env_path = nil,
    bin_path = nil,
  }

  local pixi_toml = M.find_up("pixi.toml")
  if pixi_toml and M.file_exists(pixi_toml) then
    pixi_env.project_root = vim.fn.fnamemodify(pixi_toml, ":h")

    local success, pixi_path = pcall(io.popen, "pixi info 2>/dev/null")
    if success and pixi_path then
      local info = pixi_path:read("*a")
      pixi_path:close()
      pixi_env.env_path = info and info:match("Environment path:%s+([^\n]+)")
    end

    if pixi_env.env_path then
      local bin_path = pixi_env.env_path .. "/bin"
      if M.dir_exists(bin_path) then
        pixi_env.bin_path = bin_path
      end
    end

    if not pixi_env.bin_path and pixi_env.has_pixi then
      pixi_env.bin_path = vim.fn.exepath("pixi")
    end
  end

  return pixi_env
end

function M.detect_magic_docker()
  local magic = {
    enabled = false,
    image = nil,
    config_path = nil,
  }

  local magic_config = M.find_up(".magic.docker")
  if magic_config and M.file_exists(magic_config) then
    magic.enabled = true
    magic.config_path = magic_config

    local success, file = pcall(io.open, magic_config, "r")
    if success and file then
      local content = file:read("*all")
      file:close()
      magic.image = content:match('IMAGE="([^"]+)"') or content:match("IMAGE='([^']+)'")
    end
  end

  return magic
end

function M.detect_environment()
  local mojo_env = M.detect_mojo_env()
  local gpu_env = M.detect_gpu()
  local pixi_env = M.setup_pixi_env()
  local magic_docker = M.detect_magic_docker()

  return {
    mojo = {
      has_pixi = mojo_env.has_pixi,
      has_mojo = mojo_env.has_mojo,
      has_modular = mojo_env.has_modular,
      has_max = mojo_env.has_max,
      mojo_path = mojo_env.mojo_path,
      pixi_project = mojo_env.pixi_project,
      in_docker = mojo_env.in_docker,
    },
    pixi = {
      has_pixi = pixi_env.has_pixi,
      bin_path = pixi_env.bin_path,
      env_path = pixi_env.env_path,
      project_root = pixi_env.project_root,
    },
    gpu = {
      has_nvidia = gpu_env.has_nvidia,
      has_amd = gpu_env.has_amd,
      has_intel = gpu_env.has_intel,
      cuda_version = gpu_env.cuda_version,
      rocm_version = gpu_env.rocm_version,
      driver_version = gpu_env.driver_version,
      gpu_count = gpu_env.gpu_count,
    },
    docker = {
      has_docker = mojo_env.has_docker,
      magic_enabled = magic_docker.enabled,
      magic_image = magic_docker.image,
      magic_config = magic_docker.config_path,
    },
    system = {
      os = M.get_os_name(),
      is_linux = M.is_linux(),
      is_macos = M.is_macos(),
      is_windows = M.is_windows(),
    },
  }
end

function M.setup()
  M.load_parser_library()
  M.setup_ts_runtime_path()
  return M.detect_environment()
end
function M.health_check()
  local env = M.detect_environment()
  local health = {
    status = "ok",
    issues = {},
    features = {},
  }
  if env.mojo.has_mojo then
    table.insert(health.features, "Mojo compiler available")
  else
    table.insert(health.issues, "Mojo compiler not found")
  end

  if env.pixi.has_pixi then
    table.insert(health.features, "Pixi package manager available")
  end

  if env.gpu.has_nvidia then
    table.insert(health.features, "NVIDIA GPU detected" .. (env.gpu.cuda_version and " (CUDA " .. env.gpu.cuda_version .. ")" or ""))
  end

  if env.gpu.has_amd then
    table.insert(health.features, "AMD GPU detected" .. (env.gpu.rocm_version and " (ROCm " .. env.gpu.rocm_version .. ")" or ""))
  end

  if #health.issues > 0 then
    health.status = "warning"
  end

  return health
end

return M
