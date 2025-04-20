-- blaze-ts.nvim/plugin/blaze-ts.lua
if vim.fn.has('nvim-0.8') ~= 1 then
  vim.api.nvim_err_writeln('blaze-ts requires Neovim >= 0.8')
  return
end

if vim.g.loaded_blaze_ts == 1 then
  return
end
vim.g.loaded_blaze_ts = 1

if not pcall(require, 'nvim-treesitter') then
end

vim.api.nvim_create_user_command('BlazeTS', function()
  require('blaze-ts').setup()
end, {})
