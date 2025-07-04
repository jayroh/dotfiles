" Color schemes / themes
" Plug 'nanotech/jellybeans.vim'
Plug 'altercation/vim-colors-solarized'
Plug 'dracula/vim', { 'as': 'dracula' }

" Language-specific plugins

" Ansible
Plug 'chase/vim-ansible-yaml'

" Ruby/Rails
Plug 'tpope/vim-rails'
Plug 'kana/vim-textobj-user'          " is a dependency of ...
Plug 'nelstrom/vim-textobj-rubyblock' " ... this.
Plug 'ecomba/vim-ruby-refactoring'    " some ruby refactoring goodness

" HTML
Plug 'editorconfig/editorconfig-vim'

" JavaScript, ES6, Typescript, Vue, React
" Plug 'pangloss/vim-javascript'
" Plug 'mxw/vim-jsx'
" Plug 'isRuslan/vim-es6'
" Plug 'HerringtonDarkholme/yats.vim'
" Plug 'posva/vim-vue'
" Plug 'mvolkmann/vim-js-arrow-function'

" Markdown
Plug 'plasticboy/vim-markdown'
Plug 'junegunn/goyo.vim'
Plug 'reedes/vim-pencil'
Plug 'chenxin-yan/footnote.nvim'

" Plumbing to make everything nicer
" ---------------------------------
" github co-pilot
Plug 'github/copilot.vim'

" Indented line guides
Plug 'lukas-reineke/indent-blankline.nvim'

" ag for vim
Plug 'rking/ag.vim'

" Sort using text objects and motions
Plug 'christoomey/vim-sort-motion'

" Copy to system clipboard using text objects and motions
Plug 'christoomey/vim-system-copy'

" This plugin provides several pairs of bracket maps.
" ... for my purposes this also provides a handy way to encode html entities
Plug 'tpope/vim-unimpaired'

" Git bindings
Plug 'tpope/vim-fugitive'

" Octo GitHub goodness
Plug 'nvim-tree/nvim-web-devicons'
Plug 'pwntester/octo.nvim'

" Auto-add `end` in Ruby, `endfunction` in Vim, etc
Plug 'RRethy/nvim-treesitter-endwise'

" Easily search for, substitute, and abbreviate multiple variants of a word.
" Also coerce variable names to other styles (snake case, camel case, etc)
Plug 'tpope/vim-abolish'

" Fuzzy-finder
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'

" Trim trailing whitespace on write
Plug 'derekprior/vim-trimmer'

" When editing deeply/nested/file, auto-create deeply/nested/ dirs
Plug 'duggiefresh/vim-easydir'

" Cool statusbar
Plug 'nvim-lualine/lualine.nvim'

" Easily navigate directories
Plug 'tpope/vim-vinegar'

" Make working with shell scripts nicer ("vim-unix")
Plug 'tpope/vim-eunuch'

" Surround selected text intelligently
Plug 'tpope/vim-surround'
Plug 'sustech-data/wildfire.nvim'

" Make `.` work to repeat plugin actions too
Plug 'tpope/vim-repeat'

" File explorer / file drawer
Plug 'MunifTanjim/nui.nvim'        " a dependency of ...
Plug 'nvim-neo-tree/neo-tree.nvim' " ...this

" For quick motion and moving around your buffer(s)
Plug 'ggandor/leap.nvim'

" Buffer management made easy(-ier)
Plug 'troydm/easybuffer.vim'

" Neomake fullfills the same job Syntastic had previously, except it's async
Plug 'benekastah/neomake'

" Autoformat code!
Plug 'sbdchd/neoformat'

" Sort tailwind classes on save
Plug 'laytan/tailwind-sorter.nvim', { 'do': 'cd formatter && npm i && npm run build' }

" Line up text nicely (for projects that are used to the convention)
Plug 'godlygeek/tabular'

" Ctag management
Plug 'ludovicchabant/vim-gutentags'

" Smooth scrolling
Plug 'karb94/neoscroll.nvim'

" Highlight all instances of word cursor is on, in current buffer
Plug 'RRethy/vim-illuminate'

" LSP and completion and linting
Plug 'williamboman/mason.nvim'
Plug 'williamboman/mason-lspconfig.nvim'
Plug 'WhoIsSethDaniel/mason-tool-installer.nvim'
Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/nvim-cmp'
Plug 'folke/trouble.nvim'
Plug 'mfussenegger/nvim-lint'

" Snippets
Plug 'hrsh7th/cmp-vsnip'
Plug 'hrsh7th/vim-vsnip'
Plug 'hrsh7th/vim-vsnip-integ'

" Automatically match any brackets, parentheses or quotes when you’re typing
Plug 'Raimondi/delimitMate'

" A Vim wrapper for running tests on different granularities.
Plug 'vim-test/vim-test'

" Switching from single to multiple line statements
" gS to split into multiple lines
" gJ to join into one line
Plug 'AndrewRadev/splitjoin.vim'

" Vim and Tmux sitting in a tree ...
" ----------------------------------

" Set up statusline theme(s)
Plug 'edkolev/tmuxline.vim'

" To navigate with ctrl+h/j/k/l across tmux and vim windows
Plug 'christoomey/vim-tmux-navigator'

" Make vim and tmux work together with some crazy voodoo sorcery
Plug 'christoomey/vim-tmux-runner'
