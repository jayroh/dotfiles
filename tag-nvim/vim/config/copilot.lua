local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true, expr = true }

map("i", "<C-j>", 'copilot#Accept("<CR>")', opts)

vim.g.copilot_no_tab_map = true
vim.g.copilot_assume_mapped = true
vim.g.copilot_tab_fallback = ""
vim.g.copilot_filetypes = {
  ['*']      = false,
  css        = true,
  eruby      = true,
  javascript = true,
  ruby       = true,
  sql        = true,
  typescript = true,
  vim        = true,
  yaml       = true,
}