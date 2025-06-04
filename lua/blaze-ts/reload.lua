-- blaze-ts.nvim/lua/blaze-ts/reload.lua
-- --------------------------------------
-- luacheck: globals vim
local Reload = {}

---@private
local function purge_package_cache()
  local cache = (_G.__luacache or {}).cache
  for name in pairs(package.loaded) do
    if name:match("^blaze%-ts") then
      package.loaded[name] = nil
      if cache then cache[name] = nil end
    end
  end
end
function Reload.run()
  purge_package_cache()
  local ok, mod = pcall(require, "blaze-ts")
  if ok and mod and mod.setup then
    pcall(mod.setup)
    vim.notify("blaze‑ts configuration reloaded", vim.log.levels.INFO)
  else
    vim.notify("Failed to reload blaze‑ts", vim.log.levels.ERROR)
  end
end
return Reload
