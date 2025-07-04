vim.api.nvim_create_augroup('startup', { clear = true })

-- If we launched vim without specifying a target, we want to open the pwd
vim.api.nvim_create_autocmd('VimEnter', {
  group = 'startup',
  pattern = '*',
  callback = function()
    if vim.fn.empty(vim.fn.argv()) == 1 then
      vim.cmd('silent! edit .')
    end
  end,
})