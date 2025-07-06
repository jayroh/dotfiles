-- Stop highlighting a searched word
vim.keymap.set('n', '<leader>hl', '<cmd>noh<cr>', { desc = 'Clear search highlights' })

-- Map 'ctrl-s' to save buffer
vim.keymap.set('n', '<C-S>', ':w<cr>', { noremap = true })        -- for normal mode ...
vim.keymap.set('i', '<C-S>', '<Esc>:w<cr>i', { noremap = true })  -- for insert mode

-- Switch to last buffer when in normal mode
vim.keymap.set('n', '<leader>,', '<C-^>', { desc = 'Switch to last buffer' })

-- Open up telescope to find a file
vim.keymap.set('n', '<C-p>', function()
	require('telescope.builtin').find_files()
end, { desc = 'Find files' })

-- Reload all of neovim
vim.keymap.set('n', '<leader>rl', function()
	dofile(vim.env.MYVIMRC)
	vim.notify('Nvim config reloaded!')
end, { desc = 'Reload Neovim config' })

