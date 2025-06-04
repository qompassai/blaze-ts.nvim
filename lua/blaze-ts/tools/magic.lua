--blaze-ts.nvim/lua/blaze-ts/tools/magic.lua
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
