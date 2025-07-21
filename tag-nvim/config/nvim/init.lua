-- allow for local, per-project vimrc configuration
vim.opt.exrc = true

-- line number
vim.opt.number = true -- Show absolute line numbers
vim.opt.relativenumber = true -- Show relative line numbers

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = ","
vim.g.maplocalleader = "\\"

-- Add hyphen, `-`, to iskeyword (see `:help iskeyword` for more) so that the
-- hyphen is not used as a word separator. For example, by default if we had a
-- variable named `is-keyword` and the cursor was somewhere in "keyword",
-- running `diw` would only delete "keyword", and not "is-keyword". By updating
-- this setting all of "is-keyword" would be considered one word.
--
-- This will help with autocomplete as well. Trying to auto complete "is" by
-- default would do nothing, but now it will try to autocomplete "is-keyword".
-- This is super helpful for when you are editing (S)CSS selectors.
vim.opt.iskeyword:append("-")

-- vim-plug loads all the filetype, syntax and colorscheme files, so turn them on
-- _after_ loading plugins.
vim.cmd("filetype plugin indent on")
vim.opt.sw = 4
vim.opt.ts = 4
vim.cmd("syntax enable")

-- vim-textobj-rubyblock requires that the matchit.vim plugin is enabled.
vim.cmd("runtime macros/matchit.vim")

vim.cmd("highlight Comment cterm=italic gui=italic")

-- config python host
vim.g.python3_host_prog = vim.fn.exepath("python3")

-- config ruby host
vim.g.ruby_host_prog = vim.fn.exepath("neovim-ruby-host")

-- snippet location
vim.g.vsnip_snippet_dir = "~/.dotfiles/tag-nvim/snippets"

-- ignore perl
vim.g.loaded_perl_provider = 0

-- disable automatic folding
vim.opt.foldenable = false

vim.opt.colorcolumn = "100"

-- load configs
require("config.lazy")
require("config.keymaps")
require("config.tmux")
