-- Map <leader>sv to reload the main neovim config file
vim.keymap.set('n', '<leader>rl', ':source ~/.config/nvim/init.vim<cr>', { noremap = true })

-- Map <leader><leader> to switch to previous file
vim.keymap.set('n', '<leader><leader>', '<c-^>', { noremap = true })

-- Set <leader>c to clear search highlighting
vim.keymap.set('n', '<leader>nh', ':nohlsearch<cr>', { noremap = true })

-- Run ctags
vim.keymap.set('n', '<leader>ct', ':!ctags -R .<cr>', { noremap = true })

-- Open Neotree
vim.keymap.set('n', '<leader>nt', ':Neotree toggle<cr>', { noremap = true })