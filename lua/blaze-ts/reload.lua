---/blaze-ts.nvim/lua/blaze-ts/reload.lua
-----------------------------------------
local M = {}
---
function M.reload_config()
---@diagnostic disable-next-line: undefined-field
  local luacache = (_G.__luacache or {}).cache
  for pkg, _ in pairs(package.loaded) do
    if pkg:match('^blaze_ts') then
      package.loaded[pkg] = nil
      if luacache then
        luacache[pkg] = nil
      end
    end
  end
  require("blaze-ts").setup()
  vim.notify('blaze-ts configuration reloaded!', vim.log.levels.INFO)
end
---
return M
