--- blaze-ts.nvim/lua/blaze-ts/init.lua
---------------------------------------
local M = {}

function M.setup(opts)
  opts = opts or {}
  local current_dir = debug.getinfo(1).source:match("@?(.*/)") or "./"
  local parent_dir = current_dir .. "../"
  local blaze_lib_path = parent_dir .. "blaze_lib.lua"
  local success, blaze_lib = pcall(dofile, blaze_lib_path)
  if not success then
    vim.notify("blaze_lib.lua not found, using built-in utils", vim.log.levels.INFO)
    blaze_lib = nil
  end
  if blaze_lib and blaze_lib.load then
    blaze_lib.load()
  end
  if blaze_lib and blaze_lib.setup_runtime then
    blaze_lib.setup_runtime()
  else
    local utils_success, utils = pcall(require, "blaze-ts.utils")
    if utils_success then
      utils.setup_ts_runtime_path()
    else
      vim.notify("Failed to load blaze-ts.utils", vim.log.levels.WARN)
    end
  end
  local env = {}
  local utils_success, utils = pcall(require, "blaze-ts.utils")
  if utils_success and utils.detect_environment then
    local env_success, env_result = pcall(utils.detect_environment)
    if env_success then
      env = env_result
      vim.notify("Environment detected using blaze-ts.utils", vim.log.levels.DEBUG)
    else
      vim.notify("Error calling utils.detect_environment: " .. tostring(env_result), vim.log.levels.WARN)
    end
  elseif blaze_lib and blaze_lib.detect_environment then
    local env_success, env_result = pcall(blaze_lib.detect_environment)
    if env_success then
      env = env_result
      vim.notify("Environment detected using blaze_lib", vim.log.levels.DEBUG)
    else
      vim.notify("Error calling blaze_lib.detect_environment: " .. tostring(env_result), vim.log.levels.WARN)
    end
  else
    vim.notify("Using fallback environment detection", vim.log.levels.INFO)
    local has_nvidia = vim.fn.executable("nvidia-smi") == 1
    local cuda_version = nil
    if has_nvidia then
      local handle = io.popen("nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits 2>/dev/null")
      if handle then
        cuda_version = handle:read("*a"):gsub("%s+", "")
        handle:close()
        if cuda_version == "" then
          cuda_version = nil
        end
      end
    end
    local has_pixi = vim.fn.executable("pixi") == 1
    local pixi_path = has_pixi and vim.fn.exepath("pixi") or nil
    env = {
      mojo = { has_pixi = has_pixi },
      pixi = {
        has_pixi = has_pixi,
        bin_path = pixi_path,
      },
      gpu = {
        has_nvidia = has_nvidia,
        cuda_version = cuda_version,
      },
    }
  end
  vim.g.blaze_ts = vim.g.blaze_ts or {}
  if env.mojo and env.mojo.has_pixi and env.pixi and env.pixi.has_pixi then
    vim.g.mojo_pixi_enabled = true
    vim.g.blaze_ts.pixi_path = env.pixi.bin_path
    vim.notify("Pixi environment detected", vim.log.levels.INFO)
  end
  if env.gpu and env.gpu.has_nvidia then
    vim.g.blaze_ts.has_gpu = true
    vim.g.blaze_ts.cuda_version = env.gpu.cuda_version
    vim.g.mojo_has_gpu = true
    vim.g.mojo_cuda_version = env.gpu.cuda_version
    if env.gpu.cuda_version then
      vim.notify("NVIDIA GPU detected with CUDA " .. env.gpu.cuda_version, vim.log.levels.INFO)
    else
      vim.notify("NVIDIA GPU detected", vim.log.levels.INFO)
    end
  end
  vim.filetype.add({
    extension = {
      mojo = "mojo",
      ["🔥"] = "mojo",
    },
  })
  local parser_success, parser = pcall(require, "blaze-ts.parser")
  if parser_success then
    local parser_setup_success, parser_setup_error = pcall(parser.setup)
    if parser_setup_success then
      vim.notify("Mojo parser setup completed successfully", vim.log.levels.INFO)
    else
      vim.notify("Failed to setup Mojo parser: " .. tostring(parser_setup_error), vim.log.levels.WARN)

      local setup_success, setup_error = pcall(parser.setup_parser_paths)
      if not setup_success then
        vim.notify("Failed to setup parser paths: " .. tostring(setup_error), vim.log.levels.WARN)
      end
      local config_success, config_error = pcall(parser.setup_parser_configs)
      if not config_success then
        vim.notify("Failed to setup parser configs: " .. tostring(config_error), vim.log.levels.WARN)
      end
      local path_success, has_parser = pcall(parser.get_parser_path)
      if path_success and not has_parser then
        local install_success, install_error = pcall(parser.install_parser)
        if not install_success then
          vim.notify("Failed to install parser: " .. tostring(install_error), vim.log.levels.WARN)
        end
      elseif not path_success then
        vim.notify("Failed to check parser path: " .. tostring(has_parser), vim.log.levels.WARN)
      end
    end
  else
    vim.notify("Failed to load blaze-ts.parser: " .. tostring(parser), vim.log.levels.WARN)
    local ts_success, ts_parsers = pcall(require, "nvim-treesitter.parsers")
    if ts_success then
      local config_success, parser_config = pcall(ts_parsers.get_parser_configs)
      if config_success then
        if not parser_config.mojo then
          parser_config.mojo = {
            install_info = {
              url = "https://github.com/lsh/tree-sitter-mojo",
              files = { "src/parser.c", "src/scanner.c" },
              branch = "main",
              generate_requires_npm = false,
              requires_generate_from_grammar = false,
            },
            filetype = "mojo",
          }
          vim.notify("Fallback: Mojo parser config registered manually", vim.log.levels.INFO)
        end
      else
        vim.notify("Failed to get parser configs: " .. tostring(parser_config), vim.log.levels.WARN)
      end
    else
      vim.notify("nvim-treesitter not available: " .. tostring(ts_parsers), vim.log.levels.WARN)
    end
  end
  if opts.config ~= false then
    local config_success, config = pcall(require, "blaze-ts.config")
    if config_success then
      local setup_success, setup_error = pcall(config.setup, opts.config or {})
      if setup_success then
        vim.notify("blaze-ts.config setup completed", vim.log.levels.DEBUG)
      else
        vim.notify("Failed to setup blaze-ts.config: " .. tostring(setup_error), vim.log.levels.WARN)
      end
    else
      vim.notify("blaze-ts.config not available: " .. tostring(config), vim.log.levels.WARN)
    end
  end
  if opts.lsp ~= false then
    local lsp_success, lsp = pcall(require, "blaze-ts.lsp")
    if lsp_success then
      local setup_success, setup_error = pcall(lsp.setup, opts.lsp or {})
      if setup_success then
        vim.notify("blaze-ts.lsp setup completed", vim.log.levels.DEBUG)
      else
        vim.notify("Failed to setup blaze-ts.lsp: " .. tostring(setup_error), vim.log.levels.WARN)
      end
    else
      vim.notify("blaze-ts.lsp not available: " .. tostring(lsp), vim.log.levels.WARN)
    end
  end
  vim.notify("blaze-ts.nvim setup completed", vim.log.levels.INFO)
  return M
end
function M.setup_utils()
  local utils_success, utils = pcall(require, "blaze-ts.utils")
  if utils_success then
    if utils.setup then
      local setup_success, setup_error = pcall(utils.setup)
      if setup_success then
        vim.notify("blaze-ts.utils setup completed", vim.log.levels.DEBUG)
        return utils.detect_environment()
      else
        vim.notify("Failed to setup utils: " .. tostring(setup_error), vim.log.levels.WARN)
      end
    else
      vim.notify("utils.setup function not available", vim.log.levels.WARN)
    end
  else
    vim.notify("Failed to load blaze-ts.utils: " .. tostring(utils), vim.log.levels.ERROR)
  end
  return nil
end
function M.health_check()
  local health = {
    blaze_lib = false,
    utils = false,
    parser = false,
    parser_installed = false,
    treesitter = false,
    config = false,
    lsp = false,
    pixi = false,
    gpu = false,
    environment = {},
  }
  local current_dir = debug.getinfo(1).source:match("@?(.*/)") or "./"
  local parent_dir = current_dir .. "../"
  local blaze_lib_path = parent_dir .. "blaze_lib.lua"
  local f = io.open(blaze_lib_path, "r")
  if f then
    f:close()
    health.blaze_lib = true
  end
  local utils_success, utils = pcall(require, "blaze-ts.utils")
  if utils_success then
    health.utils = true
    if utils.detect_environment then
      local env_success, env = pcall(utils.detect_environment)
      if env_success then
        health.environment = env
      end
    end
  end
  local parser_success, parser = pcall(require, "blaze-ts.parser")
  if parser_success then
    health.parser = true
    if parser.get_parser_path then
      local path_success, parser_path = pcall(parser.get_parser_path)
      if path_success and parser_path then
        health.parser_installed = true
      end
    end
  end
  local ts_success = pcall(require, "nvim-treesitter.parsers")
  health.treesitter = ts_success
  local config_success = pcall(require, "blaze-ts.config")
  health.config = config_success
  local lsp_success = pcall(require, "blaze-ts.lsp")
  health.lsp = lsp_success
  health.pixi = vim.fn.executable("pixi") == 1
  health.gpu = vim.fn.executable("nvidia-smi") == 1
  return health
end
function M.install_parser()
  local parser_success, parser = pcall(require, "blaze-ts.parser")
  if parser_success then
    return parser.install_parser()
  else
    vim.notify("Parser module not available", vim.log.levels.ERROR)
    return false
  end
end
function M.parser_health()
  local parser_success, parser = pcall(require, "blaze-ts.parser")
  if parser_success and parser.health then
    return parser.health()
  else
    vim.notify("Parser health check not available", vim.log.levels.WARN)
    return nil
  end
end
function M.reinstall_parser()
  local parser_success, parser = pcall(require, "blaze-ts.parser")
  if parser_success and parser.reinstall_parser then
    return parser.reinstall_parser()
  else
    vim.notify("Parser reinstall not available", vim.log.levels.ERROR)
    return false
  end
end
function M.detect_environment()
  local utils_success, utils = pcall(require, "blaze-ts.utils")
  if utils_success and utils.detect_environment then
    return utils.detect_environment()
  else
    return M.health_check().environment
  end
end
vim.api.nvim_create_user_command("BlazeHealth", function()
  local health = M.health_check()
  print("=== Blaze-TS Health Check ===")
  for key, value in pairs(health) do
    if type(value) == "table" and key ~= "environment" then
      print(key .. ": " .. vim.inspect(value))
    elseif key ~= "environment" then
      print(key .. ": " .. tostring(value))
    end
  end
  if health.environment and next(health.environment) then
    print("\nEnvironment:")
    print(vim.inspect(health.environment))
  end
end, { desc = "Run Blaze-TS health check" })
vim.api.nvim_create_user_command("BlazeParserHealth", function()
  M.parser_health()
end, { desc = "Check Mojo parser health" })
vim.api.nvim_create_user_command("BlazeReinstallParser", function()
  M.reinstall_parser()
end, { desc = "Reinstall Mojo parser" })
return M
