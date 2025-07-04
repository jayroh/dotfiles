vim.g.markdown_fenced_languages = {'ruby', 'sh', 'yaml', 'javascript', 'html', 'css'}

-- open macdown to preview the output of a markdown file
vim.keymap.set('n', '<leader>mdp', ':w<cr>:silent! !open -a MacDown % > /dev/null &<cr>:redraw!<cr>', { noremap = true })