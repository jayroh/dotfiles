-- Enable filetype detection and indentation
vim.cmd('filetype indent plugin on')

-- Autoindent CSS and JSON files
vim.api.nvim_create_augroup('autoindent', { clear = true })
vim.api.nvim_create_autocmd('BufWritePre', {
  group = 'autoindent',
  pattern = { '*.css', '*.json' },
  command = 'normal migg=G`i',
})

-- File type assignments
vim.api.nvim_create_augroup('myfiletypes', { clear = true })

-- YAML files
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  group = 'myfiletypes',
  pattern = { '*.yml', '*.yaml', '*.yml.j2' },
  command = 'set ft=yaml',
})

-- JavaScript files
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  group = 'myfiletypes',
  pattern = { '*.es6', '*.js' },
  command = 'set ft=javascript',
})

-- Shell scripts
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  group = 'myfiletypes',
  pattern = '*.sh',
  command = 'set ft=sh',
})

-- ERB files
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  group = 'myfiletypes',
  pattern = '*.html.erb',
  command = 'set ft=eruby',
})

-- Liquid files
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  group = 'myfiletypes',
  pattern = '*.liquid',
  command = 'set ft=liquid',
})

-- Nginx config
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  group = 'myfiletypes',
  pattern = '*etc/nginx/*',
  command = 'set ft=nginx',
})

-- Crystal files
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  group = 'myfiletypes',
  pattern = '*.cr',
  command = 'set ft=crystal',
})

-- Ruby files
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  group = 'myfiletypes',
  pattern = { '*.json.jbuilder', '*.rabl', '*.ru', 'Capfile', 'Gemfile', 'Thorfile' },
  command = 'set ft=ruby',
})

-- Docker compose files
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  group = 'myfiletypes',
  pattern = { 'compose.yaml', 'compose.yml', 'docker-compose.yaml', 'docker-compose.yml' },
  command = 'set ft=yaml.docker-compose',
})

-- Disable indent line for JSON and markdown
vim.api.nvim_create_autocmd('FileType', {
  group = 'myfiletypes',
  pattern = { 'json', 'markdown' },
  callback = function()
    vim.g.indentLine_enabled = 0
  end,
})

-- Enable spell check for git commits
vim.api.nvim_create_autocmd('FileType', {
  group = 'myfiletypes',
  pattern = 'gitcommit',
  command = 'setlocal spell',
})

-- Set indentation for various file types
vim.api.nvim_create_autocmd('FileType', {
  group = 'myfiletypes',
  pattern = { 'html', 'ruby', 'eruby', 'yaml', 'vim', 'javascript', 'json', 'liquid', 'typescript', 'crystal', 'css' },
  command = 'setlocal autoindent shiftwidth=2 softtabstop=2 tabstop=2 expandtab',
})

vim.api.nvim_create_autocmd('FileType', {
  group = 'myfiletypes',
  pattern = 'html.eruby',
  command = 'setlocal autoindent shiftwidth=2 softtabstop=2 tabstop=2 expandtab',
})

-- Format on save
vim.api.nvim_create_autocmd('BufWritePre', {
  group = 'myfiletypes',
  pattern = { '*.rb', '*.rake', '*.js', '*.ts' },
  callback = function()
    vim.lsp.buf.format(nil, 2000)
  end,
})

-- Lint after save
vim.api.nvim_create_autocmd('BufWritePost', {
  group = 'myfiletypes',
  pattern = '*',
  callback = function()
    require('lint').try_lint()
  end,
})

-- Markdown file setup
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  group = 'myfiletypes',
  pattern = { '*.md', '*.markdown', 'gitcommit' },
  command = 'set ft=markdown',
})

vim.api.nvim_create_autocmd('FileType', {
  group = 'myfiletypes',
  pattern = { '*.md', '*.markdown', 'gitcommit' },
  command = 'setlocal textwidth=100',
})

vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead', 'BufWrite' }, {
  group = 'myfiletypes',
  pattern = { '*.md', '*.markdown', 'gitcommit' },
  command = 'syntax match Comment /\\%^---\\_.\\{-}---$/',
})

vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  group = 'myfiletypes',
  pattern = { '*.md', '*.markdown', 'gitcommit' },
  command = 'setlocal spell',
})

-- Markdown shortcuts
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  group = 'myfiletypes',
  pattern = { '*.md', '*.markdown', 'gitcommit' },
  callback = function()
    vim.keymap.set('n', '<leader>=', 'yypv$r=', { buffer = true })
    vim.keymap.set('n', '<leader>-', 'yypv$r-', { buffer = true })
  end,
})

-- Detect bash shebang
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile', 'BufWrite' }, {
  pattern = '*',
  callback = function()
    if vim.fn.getline(1):match("#!/bin/bash") then
      vim.bo.filetype = 'sh'
    end
  end,
})

-- Detect zsh shebang
vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile', 'BufWrite' }, {
  pattern = '*',
  callback = function()
    if vim.fn.getline(1):match("#!/bin/zsh") then
      vim.bo.filetype = 'zsh'
    end
  end,
})