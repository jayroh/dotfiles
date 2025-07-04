vim.g.ale_sign_error = '•'
vim.g.ale_sign_warning = '•'
vim.g.ale_sign_info = 'ℹ'

vim.cmd('hi link ALEErrorSign    Error')
vim.cmd('hi link ALEWarningSign  Warning')

vim.g.ale_linters = {
  javascript = {'eslint'},
  ruby = {'rubocop'},
  markdown = {'languagetool'},
  gitcommit = {'languagetool'},
}

vim.g.ale_fixers = {
  javascript = {'eslint'},
  ruby = {'rubocop'},
}

-- Only run linters named in ale_linters settings.
vim.g.ale_linters_explicit = 1

-- Disable ALE auto highlights
vim.g.ale_set_highlights = 0

-- ,aj to jump to next ale error
vim.keymap.set('n', '<leader>aj', ':ALENext<cr>', { silent = true })

-- ,ak to jump back to previous ale error
vim.keymap.set('n', '<leader>ak', ':ALEPrevious<cr>', { silent = true })

-- ,fix to automatically fix ale errors/warnings
vim.keymap.set('n', '<leader>fix', ':ALEFix<cr>', { silent = true })

-- run rubocop against this file. Moved from vim tmux runner config
vim.keymap.set('n', '<leader>bo', ':ALEFix<cr>', { silent = true })