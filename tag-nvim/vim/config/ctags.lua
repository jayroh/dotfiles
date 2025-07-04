local function generate_ctags()
  vim.fn.system("git ls-files | ctags -L -")
end

vim.api.nvim_create_user_command('Ctags', generate_ctags, {})

vim.keymap.set('n', '<leader>tv', function()
  local word = vim.fn.expand("<cword>")
  vim.cmd("vsp")
  vim.cmd("exec(\"tag \" . \"" .. word .. "\")")
end, { silent = true })