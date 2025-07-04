local function nums()
  vim.opt.relativenumber = not vim.opt.relativenumber:get()
  vim.opt.number = not vim.opt.number:get()
end

vim.keymap.set('n', '<leader>num', nums, { noremap = true })