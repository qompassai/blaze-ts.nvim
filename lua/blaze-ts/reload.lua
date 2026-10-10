-- -------------------------------------------------------------------------------
-- /qompassai/blaze-ts.nvim/lua/blaze-ts/reload.lua
-- Qompass AI Plugin reload helper
-- SPDX-License-Identifier: Apache-2.0
-- Copyright (c) 2026 Qompass AI
--
-- Licensed under the Apache License, Version 2.0 (the "License"); you may not
-- use this file except in compliance with the License. You may obtain a copy
-- of the License at http://www.apache.org/licenses/LICENSE-2.0
-- -------------------------------------------------------------------------------
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
