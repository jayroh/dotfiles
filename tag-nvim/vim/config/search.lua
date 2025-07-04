-- Stolen from mr. Gordon Fontenot almost entirely:
-- https://github.com/gfontenot/dotfiles/blob/master/tag-vim/vim/config/search.vim

vim.opt.gdefault = true      -- default to global substitutions on lines
vim.opt.ignorecase = true    -- Case-insensitive searching.
vim.opt.smartcase = true     -- But case-sensitive if expression contains a capital letter.
vim.opt.hlsearch = true      -- Highlight matches.
vim.opt.showmatch = true     -- Show all matches

-- on opening the file, clear search-highlighting
vim.api.nvim_create_autocmd('BufReadCmd', {
  pattern = '*',
  command = 'set nohlsearch',
})

-- Use Ag over Grep
vim.opt.grepprg = 'ag --nogroup --nocolor'

-- Map Gr directly to \ for speeeed
vim.keymap.set('n', '\\', ':Ag<SPACE>', { noremap = true })

-- bind K to grep word under cursor
vim.keymap.set('n', 'K', ':Ag <C-R><C-W><CR>', { noremap = true })

-- Find files using Telescope command-line sugar.
vim.keymap.set('n', '<C-p>', '<cmd>Telescope find_files<cr>', { silent = true })
vim.keymap.set('n', '<leader>ff', '<cmd>Telescope find_files<cr>', { noremap = true })
vim.keymap.set('n', '<leader>fg', '<cmd>Telescope live_grep<cr>', { noremap = true })
vim.keymap.set('n', '<leader>fb', '<cmd>Telescope buffers<cr>', { noremap = true })
vim.keymap.set('n', '<leader>fh', '<cmd>Telescope help_tags<cr>', { noremap = true })