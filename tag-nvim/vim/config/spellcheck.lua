-- Stolen from mr. Gordon Fontenot entirely:
-- https://github.com/gfontenot/dotfiles/blob/master/tag-vim/vim/config/spellcheck.vim

vim.opt.spellfile = '~/.vim/spell/en.utf-8.add'

vim.api.nvim_create_augroup('spellcheck', { clear = true })

-- recreate the spelling dictionary at startup
vim.api.nvim_create_autocmd('VimEnter', {
  group = 'spellcheck',
  pattern = '*',
  callback = function()
    vim.cmd('silent mkspell! ' .. vim.opt.spellfile:get())
  end,
})