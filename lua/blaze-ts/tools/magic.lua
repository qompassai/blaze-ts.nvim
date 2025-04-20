--blaze-ts.nvim/lua/blaze-ts/tools/magic.lua
function M.find_magic()
  local possible_paths = {
    vim.fn.expand("~/.modular/pkg/packages.modular.com_mojo/bin/magic"),
    "/usr/local/bin/magic",
  }
  
  for _, path in ipairs(possible_paths) do
    if vim.fn.executable(path) == 1 then
      return path
    end
  end
  
  return nil
end

