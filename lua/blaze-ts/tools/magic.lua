-- -------------------------------------------------------------------------------
-- /qompassai/blaze-ts.nvim/lua/blaze-ts/tools/magic.lua
-- Qompass AI Modular magic binary locator
-- SPDX-License-Identifier: Apache-2.0
-- Copyright (c) 2026 Qompass AI
--
-- Licensed under the Apache License, Version 2.0 (the "License"); you may not
-- use this file except in compliance with the License. You may obtain a copy
-- of the License at http://www.apache.org/licenses/LICENSE-2.0
-- -------------------------------------------------------------------------------
-- luacheck: globals vim

local Magic = {}
local paths = {
  vim.fn.expand("~/.modular/pkg/packages.modular.com_mojo/bin/magic"),
  "/usr/local/bin/magic",
  "/usr/bin/magic",
}
function Magic.find()
  for _, p in ipairs(paths) do
    if vim.fn.executable(p) == 1 then return p end
  end
end
return Magic
