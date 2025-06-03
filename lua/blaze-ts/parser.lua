-- blaze-ts.nvim/lua/blaze-ts/parser.lua
----------------------------------------
local M = {}
function M.get_parser_path()
  local possible_paths = {
    vim.fn.stdpath("data") .. "/lazy/nvim-treesitter/parser/mojo.so",
    vim.fn.stdpath("data") .. "/site/pack/lazy/opt/nvim-treesitter/parser/mojo.so",
    vim.fn.stdpath("data") .. "/site/pack/lazy/start/nvim-treesitter/parser/mojo.so",
    vim.fn.stdpath("data") .. "/site/pack/packer/opt/nvim-treesitter/parser/mojo.so",
    vim.fn.stdpath("data") .. "/site/pack/packer/start/nvim-treesitter/parser/mojo.so",
    vim.fn.expand("~/.local/share/nvim/site/parser/mojo.so"),
    vim.fn.stdpath("data") .. "/site/parser/mojo.so",
    vim.fn.fnamemodify(vim.fn.expand("<sfile>"), ":p:h:h:h") .. "/parser/mojo.so",
  }
  for _, path in ipairs(possible_paths) do
    if vim.fn.filereadable(path) == 1 then
      return path
    end
  end
  return nil
end
function M.load_parser(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local lang = "mojo"
  local success, parser = pcall(vim.treesitter.get_parser, bufnr, lang)
  if not success or not parser then
    vim.notify("Failed to load Mojo parser for current buffer", vim.log.levels.WARN)
    return nil
  end

  return parser
end
function M.get_tree(bufnr)
  local parser = M.load_parser(bufnr)
  if not parser then
    return nil
  end
  local success, trees = pcall(parser.parse, parser)
  if not success or not trees or #trees == 0 then
    vim.notify("Failed to parse Mojo buffer", vim.log.levels.WARN)
    return nil
  end
  return trees[1]
end
function M.is_mojo_file(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype
  local filename = vim.fn.expand("%:t")
  local extension = vim.fn.expand("%:e")
  return ft == "mojo" or extension == "mojo" or extension == "🔥" or filename:match("%.mojo$") or filename:match("%.🔥$")
end
function M.setup_parser_configs()
  local success, parser_configs = pcall(require, "nvim-treesitter.parsers")
  if not success then
    vim.notify("nvim-treesitter.parsers not available", vim.log.levels.WARN)
    return false
  end
  local parser_config = parser_configs.get_parser_configs()
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
    vim.notify("Mojo parser configuration registered", vim.log.levels.INFO)
  else
    vim.notify("Mojo parser already configured", vim.log.levels.DEBUG)
  end
  return true
end
function M.install_parser()
  if not M.setup_parser_configs() then
    return false
  end
  local ts_success, ts_install = pcall(require, "nvim-treesitter.install")
  if not ts_success then
    vim.notify("nvim-treesitter.install not available", vim.log.levels.ERROR)
    return false
  end
  local parser_name = "mojo"
  local is_installed_success, is_installed = pcall(ts_install.is_installed, parser_name)
  if is_installed_success and is_installed then
    vim.notify("Mojo parser is already installed", vim.log.levels.INFO)
    return true
  end
  vim.notify("Installing Mojo parser...", vim.log.levels.INFO)
  local install_success, result = pcall(ts_install.install_parsers, { parser_name })

  if install_success and result then
    vim.notify("Mojo parser installed successfully", vim.log.levels.INFO)
    return true
  else
    vim.notify("Failed to install Mojo parser: " .. tostring(result), vim.log.levels.ERROR)
    return false
  end
end

function M.setup_parser_paths()
  local source_file = debug.getinfo(1).source
  if source_file:sub(1, 1) == "@" then
    source_file = source_file:sub(2)
  end

  local runtime_path = vim.fn.fnamemodify(source_file, ":p:h:h:h") .. "/runtime"

  if vim.fn.isdirectory(runtime_path) == 1 then
    local rtp = vim.opt.rtp:get()
    if not vim.tbl_contains(rtp, runtime_path) then
      vim.opt.rtp:prepend(runtime_path)
      vim.notify("Added runtime path: " .. runtime_path, vim.log.levels.DEBUG)
    end
  end
end

function M.check_parser_status()
  local status = {
    config_registered = false,
    parser_installed = false,
    parser_path = nil,
    can_load = false,
  }

  local success, parser_configs = pcall(require, "nvim-treesitter.parsers")
  if success then
    local parser_config = parser_configs.get_parser_configs()
    status.config_registered = parser_config.mojo ~= nil
  end
  status.parser_path = M.get_parser_path()
  status.parser_installed = status.parser_path ~= nil

  if status.parser_installed then
    local test_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(test_buf, "filetype", "mojo")
    local parser = M.load_parser(test_buf)
    status.can_load = parser ~= nil
    vim.api.nvim_buf_delete(test_buf, { force = true })
  end

  return status
end
function M.reinstall_parser()
  vim.notify("Reinstalling Mojo parser...", vim.log.levels.INFO)

  local parser_path = M.get_parser_path()
  if parser_path then
    vim.fn.delete(parser_path)
  end

  pcall(function()
    require("nvim-treesitter.install").update({}, "mojo")
  end)
  return M.install_parser()
end
function M.setup()
  M.setup_parser_paths()
  if not M.setup_parser_configs() then
    return false
  end
  local parser_path = M.get_parser_path()
  if not parser_path then
    vim.notify("Mojo parser not found, attempting to install...", vim.log.levels.INFO)
    return M.install_parser()
  else
    vim.notify("Mojo parser found at: " .. parser_path, vim.log.levels.DEBUG)
    return true
  end
end
function M.health()
  local status = M.check_parser_status()
  print("Mojo Parser Health Check:")
  print("========================")
  print("Config registered: " .. tostring(status.config_registered))
  print("Parser installed: " .. tostring(status.parser_installed))
  print("Parser path: " .. tostring(status.parser_path or "Not found"))
  print("Can load parser: " .. tostring(status.can_load))
  if status.config_registered and status.parser_installed and status.can_load then
    print("Status: ✅ All good!")
  else
    print("Status: ⚠️  Issues detected")
    if not status.config_registered then
      print("  - Parser config not registered")
    end
    if not status.parser_installed then
      print("  - Parser not installed")
    end
    if status.parser_installed and not status.can_load then
      print("  - Parser installed but cannot load")
    end
  end
  return status
end
return M
