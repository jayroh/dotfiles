if has("autocmd")
  augroup myfiletypes
    autocmd!

    " autoindent with two spaces, always expand tabs
    au FileType ruby,eruby,yaml set autoindent shiftwidth=2 softtabstop=2 tabstop=2 expandtab
    au FileType python set autoindent shiftwidth=4 softtabstop=4 expandtab
    au FileType php,javascript,html,htmldjango,css,radius set autoindent shiftwidth=2 softtabstop=2 expandtab
    au FileType vim set autoindent tabstop=2 shiftwidth=2 softtabstop=2 expandtab
    au FileType cucumber set autoindent tabstop=2 shiftwidth=2 softtabstop=2 expandtab
    au BufEnter *.haml setlocal cursorcolumn
    au BufRead,BufNewFile *.html.erb set ft=html.eruby
    au BufRead,BufNewFile *etc/nginx/* set ft=nginx
    au BufRead,BufNewFile *.ru set ft=ruby
    au BufRead,BufNewFile *.rabl setf ruby
    au BufRead,BufNewFile Gemfile set ft=ruby
    au BufRead,BufNewFile Gemfile set ft=ruby
    au BufRead,BufNewFile Capfile set ft=ruby
    au BufRead,BufNewFile Thorfile set ft=ruby
    au BufRead,BufNewFile *.god set ft=ruby
    au BufRead,BufNewFile .caprc set ft=ruby
    au BufRead,BufNewFile *.scss set filetype=scss
    au BufRead,BufNewFile *.less set filetype=less
    au BufRead,BufNewFile *.coffee set filetype=coffee
    au BufRead,BufNewFile *.coffee set autoindent shiftwidth=2 softtabstop=2 expandtab
    au BufRead,BufNewFile *.coffee set foldmethod=indent nofoldenable
    au BufEnter *.scss setlocal cursorcolumn
    au BufEnter *.sass setlocal cursorcolumn
  augroup END


  " When editing a file, always jump to the last known cursor position.
  " Don't do it when the position is invalid or when inside an event handler
  " (happens when dropping a file on gvim).
  autocmd BufReadPost *
        \ if line("'\"") > 0 && line("'\"") <= line("$") |
        \   exe "normal g`\"" |
        \ endi
else
  set autoindent
endif
