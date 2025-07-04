vim.keymap.set('n', '<C-p>', function()
  require('telescope.builtin').find_files()
end, { desc = 'Find files' })
