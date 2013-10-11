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
set incsearch
set hlsearch
set cursorline
set showmatch
set smarttab
set scrolloff=3
set pastetoggle=<F6>
set colorcolumn=80
set encoding=utf-8
set number
set wildmenu
set wildmode=list:longest,list:full
set complete=.,w,t
set complete-=i
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
colorscheme grb256

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Vundle
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

source $HOME/.vim/autocmd.vim

" Let Vundle manage Vundle
Bundle 'gmarik/vundle'

" Define bundles via Github repos
Bundle 'thoughtbot/vim-rspec'
Bundle 'regedarek/ZoomWin.git'
Bundle 'Lokaltog/vim-powerline'
Bundle 'airblade/vim-rooter'
Bundle 'airblade/vim-gitgutter'
Bundle 'cstrahan/grb256'
Bundle 'duff/vim-scratch'
Bundle 'int3/vim-extradite'
Bundle 'kchmck/vim-coffee-script'
Bundle 'msanders/snipmate.vim'
Bundle 'sickill/vim-pasta'
Bundle 'tpope/vim-cucumber'
Bundle 'tpope/vim-endwise'
Bundle 'tpope/vim-fugitive'
Bundle 'tpope/vim-markdown'
Bundle 'tpope/vim-ragtag'
Bundle 'tpope/vim-rails'
Bundle 'tpope/vim-rvm'
Bundle 'tpope/vim-surround'
Bundle 'troydm/easybuffer.vim'
Bundle 'vim-scripts/ctags.vim'
Bundle 'vim-scripts/greplace.vim'
Bundle 'vim-scripts/tComment'
Bundle 'xenoterracide/html.vim'
Bundle 'takac/vim-commandcaps'
Bundle 'rking/ag.vim'
Bundle 'jgdavey/tslime.vim'


if executable("ag")
  set grepprg=ag\ --nogroup\ --nocolor\ --column
endif

nmap K :grep "\b<C-R><C-W>\b"<CR>:copen<CR>

let mapleader = ","
let g:Powerline_symbols = 'fancy'

nmap <leader>ct :!ctags -R --exclude=.git --exclude=log * $(rvm gemdir)<CR>
nmap <leader>z :ZoomWin<CR>
nmap <leader>sv :source $MYVIMRC<CR>
nnoremap // :TComment<CR>
vnoremap // :TComment<CR>
nnoremap <F5> :set nonumber!<CR>

scriptencoding utf-8
filetype plugin indent on

" Load matchit (% to bounce from do to end, etc.)
runtime! macros/matchit.vim

set tags=./tags;

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

" Hide search highlighting
map <silent> <leader>nh :nohls <CR>

" IRB
autocmd FileType irb inoremap <buffer> <silent> <CR> <Esc>:<C-u>ruby v=VIM::Buffer.current;v.append(v.line_number, eval(v[v.line_number]).inspect)<CR>
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
" map <leader>gR :call ShowRoutes()<cr>
" map <leader>gv :CommandTFlush<cr>\|:CommandT app/views<cr>
" map <leader>gc :CommandTFlush<cr>\|:CommandT app/controllers<cr>
" map <leader>gm :CommandTFlush<cr>\|:CommandT app/models<cr>
" map <leader>gh :CommandTFlush<cr>\|:CommandT app/helpers<cr>
" map <leader>gl :CommandTFlush<cr>\|:CommandT lib<cr>
" map <leader>gp :CommandTFlush<cr>\|:CommandT public<cr>
" map <leader>gs :CommandTFlush<cr>\|:CommandT public/stylesheets/sass<cr>
" map <leader>gf :CommandTFlush<cr>\|:CommandT features<cr>
" map <leader>gt :CommandTFlush<cr>\|:CommandT spec<cr>
" map <leader>f :CommandTFlush<cr>\|:CommandT<cr>
" map <leader>F :CommandTFlush<cr>\|:CommandT %%<cr>

map <leader>w :call TrimWhiteSpace()<cr>
map! <leader>w :call TrimWhiteSpace()<cr>

map <leader>bv :EasyBufferVerticalRight<cr>
map <leader>bs :EasyBufferHorizontalBelow<cr>
map <leader>be :EasyBuffer<cr>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Git Gutter
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
highlight clear signcolumn
let g:gitgutter_enabled = 0
nmap <leader>gu :GitGutterToggle<CR>

" Switch between the last two files
nnoremap <leader><leader> <c-^>

" Bundle! Gemfile!
nnoremap <leader>bun :!bundle<CR>
nnoremap <leader>gem :tabe Gemfile<CR>
nnoremap <leader>db :tabe db/schema.rb<CR>
nnoremap <leader>route :tabe config/routes.rb<CR>

source $HOME/.vim/functions.vim
