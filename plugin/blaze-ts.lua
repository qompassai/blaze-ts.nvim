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
  vim.api.nvim_err_writeln('blaze-ts.nvim requires nvim-treesitter')
  return
end
vim.api.nvim_create_user_command('BlazeTS', function()
  require('blaze-ts').setup()
end, { desc = "Setup Blaze TreeSitter for Mojo" })
vim.api.nvim_create_autocmd("FileType", {
  pattern = "mojo",
  once = true,
  callback = function()
    local parser_ok = pcall(vim.treesitter.get_parser, 0, "mojo")
    if not parser_ok then
      vim.schedule(function()
        local success = pcall(vim.cmd, "TSInstall mojo")
        if not success then
          vim.notify("Failed to install Mojo parser. Try running :TSInstall mojo manually", vim.log.levels.WARN)
        end
      end)
    end
  end,
})
