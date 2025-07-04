-- Set <leader>be to open up list of buffers
vim.keymap.set('n', '<leader>bv', ':EasyBufferVerticalRight<cr>', { noremap = true })
vim.keymap.set('n', '<leader>bh', ':EasyBufferHorizontalBelow<cr>', { noremap = true })
vim.keymap.set('n', '<leader>be', ':EasyBuffer<cr>', { noremap = true })