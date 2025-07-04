vim.api.nvim_create_autocmd("VimResized", {
  pattern = "*",
  command = "wincmd =",
})