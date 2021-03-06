set backspace=indent,eol,start
set t_Co=256
set splitbelow
set splitright
set shell=/bin/zsh
set directory=/tmp/
set winwidth=84
set winheight=20
set winminheight=20
set winheight=999
set nocompatible
set nojoinspaces
set incsearch
set hlsearch
set cursorline
set showmatch
set smarttab
set scrolloff=3
set colorcolumn=80
set encoding=utf-8
set relativenumber
set number
set wildmenu
set wildmode=list:longest,list:full
set list listchars=tab:»·,trail:·
set gdefault
set foldenable
" Nice statusbar
set laststatus=2
set statusline=\ "
set statusline+=%f\ " file name
set statusline+=[
set statusline+=%{strlen(&ft)?&ft:'none'}, " filetype
set statusline+=%{&fileformat}] " file format
set statusline+=%h%1*%m%r%w%0* " flag
set statusline+=%= " right align
set statusline+=%-14.(%l,%c%V%)\ %<%P " offset
set title
set titlestring=VIM:\ %-25.55F\ %a%r%m titlelen=70
setlocal numberwidth=5
syntax on

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Vundle
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

" Let Vundle manage Vundle
Bundle 'gmarik/vundle'

" Define bundles via Github repos
Bundle 'avakhov/vim-yaml'
Bundle 'nanotech/jellybeans.vim'
Bundle 'mattn/emmet-vim'
Bundle 'scrooloose/syntastic'
Bundle 'ctrlpvim/ctrlp.vim'
Bundle 'dockyard/vim-easydir'
Bundle 'mattn/webapi-vim'
Bundle 'christoomey/vim-tmux-navigator'
Bundle 'christoomey/vim-rfactory'
Bundle 'christoomey/vim-quicklink'
Bundle 'thoughtbot/vim-rspec'
Bundle 'regedarek/ZoomWin.git'
Bundle 'Lokaltog/vim-powerline'
Bundle 'airblade/vim-rooter'
Bundle 'duff/vim-scratch'
Bundle 'int3/vim-extradite'
Bundle 'kchmck/vim-coffee-script'
Bundle 'msanders/snipmate.vim'
Bundle 'sickill/vim-pasta'
Bundle 'tpope/vim-commentary'
Bundle 'tpope/vim-cucumber'
Bundle 'tpope/vim-endwise'
Bundle 'tpope/vim-fugitive'
Bundle 'tpope/vim-markdown'
Bundle 'tpope/vim-ragtag'
Bundle 'tpope/vim-rails'
Bundle 'tpope/vim-surround'
Bundle 'troydm/easybuffer.vim'
Bundle 'vim-ruby/vim-ruby'
Bundle 'vim-scripts/ctags.vim'
Bundle 'vim-scripts/greplace.vim'
Bundle 'xenoterracide/html.vim'
Bundle 'takac/vim-commandcaps'
Bundle 'rking/ag.vim'
Bundle 'jgdavey/tslime.vim'
Bundle 'tmhedberg/matchit'
Bundle 'kana/vim-textobj-user'
Bundle 'nelstrom/vim-textobj-rubyblock'
Bundle 'vim-scripts/nginx.vim'
" Bundle 'fatih/vim-go'

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Colors
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

try
  colorscheme jellybeans
catch /^Vim\%((\a\+)\)\=:E185/
  echo "Install the jellybeans colorscheme"
endtry

if executable('ag')
  " Use ag over grep
  set grepprg=ag\ --nogroup\ --nocolor\ --column

  " Use ag in CtrlP for listing files. Lightning fast and respects .gitignore
  let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'

  " ag is fast enough that CtrlP doesn't need to cache
  let g:ctrlp_use_caching = 0
endif

nmap K :Ag "\b<C-R><C-W>\b"<CR>

let mapleader = ","
let g:Powerline_symbols = 'fancy'
let g:markdown_fenced_languages = ['javascript', 'ruby', 'sh', 'yaml', 'javascript', 'html', 'vim', 'coffee', 'json', 'diff']

map <leader>pre :w<cr>:silent! !open -a MacDown % > /dev/null &<cr>:redraw!<cr>
nmap <leader>z :zoomwin<cr>
nmap <leader>pa :set nonumber! norelativenumber! nopaste!<cr>

scriptencoding utf-8
filetype plugin indent on

" Exuberant Ctags
nmap <leader>ct :!ctags -R --exclude=.git --exclude=log<cr>
set tags=./tags;
set complete=.,t

" Load matchit (% to bounce from do to end, etc.)
runtime! macros/matchit.vim

" Turn off rails bits of statusbar
let g:rails_statusline=0
let g:browser = 'open '

if exists(":CoffeeMake")
  nmap <leader>cc :silent CoffeeMake<CR>
  nmap <leader>cv :CoffeeCompile watch vert<CR>
endif

" Quickly change quotes
vnoremap <leader>c' :s/"/'/<CR>
vnoremap <leader>c" :s/'/"/<CR>
nmap "" cs'"
nmap '' cs"'

" Tab navigation
nmap <leader>tl :tabnext<CR>
nmap <leader>th :tabprevious<CR>
nmap <leader>te :tabedit<CR>:e 
nmap <leader>1 1gt
nmap <leader>2 2gt
nmap <leader>3 3gt
nmap <leader>4 4gt
nmap <leader>5 5gt
nmap <leader>6 6gt
nmap <leader>7 7gt
nmap <leader>8 8gt
nmap <leader>9 9gt
nmap <leader>0 10gt

" Remap F1 from Help to ESC.  No more accidents.
nmap <F1> <Esc>
map! <F1> <Esc>

" search next/previous -- center in page
nmap n nzz
nmap N Nzz
nmap * *Nzz
nmap # #nzz

" Yank from the cursor to the end of the line, to be consistent with C and D.
nnoremap Y y$

" copy entire buffer
nnoremap <leader>aa :%y+<cr>

" Hide search highlighting
map <silent> <leader>nh :nohls <CR>

" IRB
nnoremap <leader>irb :<C-u>below new<CR>:setfiletype irb<CR>:set syntax=ruby<CR>:set buftype=nofile<CR>:set bufhidden=delete<CR>i

map <C-c>n :cnext<CR>
map <C-c>p :cprevious<CR>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" OPEN FILES IN DIRECTORY OF CURRENT FILE
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
cnoremap %% <C-R>=expand('%:h').'/'<cr>
map <Leader>e :e <C-R>=expand("%:p:h") . "/" <CR>
map <leader>v :v <C-R>=expand("%:p:h") . "/" <CR>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" MAPS TO JUMP TO SPECIFIC COMMAND-T TARGETS AND FILES
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
map <leader>gr :topleft :split config/routes.rb<cr>
map <leader>gg :topleft 100 :split Gemfile<cr>

map <leader>w :call TrimWhiteSpace()<cr>
map! <leader>w :call TrimWhiteSpace()<cr>

map <leader>bv :EasyBufferVerticalRight<cr>
map <leader>bs :EasyBufferHorizontalBelow<cr>
map <leader>be :EasyBuffer<cr>

" Switch between the last two files
nnoremap <leader><leader> <c-^>

" Bundle! Gemfile!
nnoremap <leader>gem :tabe Gemfile<CR>
noremap <leader>db :tabe db/schema.rb<CR>
nnoremap <leader>route :tabe config/routes.rb<CR>

" Syntastic
let g:syntastic_html_tidy_exec = 'tidy5'
let g:syntastic_ruby_checkers = ['mri', 'rubocop']
let g:syntastic_html_tidy_ignore_errors = [ 'trimming empty <span>', 'possibly useless use of a variable in void context' ]
let g:syntastic_quiet_messages = { "regex": 'possibly useless use of a variable in void context' }

" Fugitive
" command Gprettylog :Git! log --all --graph --decorate --oneline --simplify-by-decoration
" command Greview :Git! diff --staged
" nnoremap <leader>gr :Greview<cr>
" nnoremap <leader>glog :Gprettylog<cr>

" FactoryGirl - https://github.com/christoomey/vim-rfactory
map <leader>fact :RVfactory<CR>

source $HOME/.vim/rcfiles/autocmd.vim
source $HOME/.vim/rcfiles/functions.vim
source $HOME/.vim/rcfiles/emmet.vim
