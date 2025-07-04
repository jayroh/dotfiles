vim.g.tmux_navigator_save_on_switch = 1

if vim.fn.has('nvim') == 1 then
  vim.keymap.set('n', '<BS>', '<C-W>h', { noremap = true })
end