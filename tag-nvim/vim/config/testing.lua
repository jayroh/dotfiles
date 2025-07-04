-- make test commands execute using Vim Tmux Runner[1]
vim.g['test#strategy'] = "vtr"
--[1]: https://github.com/christoomey/vim-tmux-runner

-- Turn off usage of binstubs. Force it to use bundle exec.
vim.g['test#ruby#use_binstubs'] = 0

vim.keymap.set('n', '<leader>f', ':VtrSendCommandToRunner bundle exec rspec --only-failures<cr>', { silent = true })  -- run the last failures
vim.keymap.set('n', '<leader>t', ':TestFile<cr>', { silent = true })    -- run tests in current file/buffer
vim.keymap.set('n', '<leader>l', ':TestLast<cr>', { silent = true })    -- repeat last test command
vim.keymap.set('n', '<leader>s', ':TestNearest<cr>', { silent = true }) -- run the test closes to the cursor
vim.keymap.set('n', '<leader>to', ':TestVisit<cr>', { silent = true })  -- open the last test file in the buffer