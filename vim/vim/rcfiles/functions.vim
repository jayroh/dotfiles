 if !exists("*ShowRoutes")
  function! ShowRoutes()
    " Requires 'scratch' plugin
    :topleft 100 :split __Routes__
    " Make sure Vim doesn't write __Routes__ as a file
    :set buftype=nofile
    " Delete everything
    :normal 1GdG
    " Put routes output in buffer
    :0r! rake -s routes
    " Size window to number of lines (1 plus rake output length)
    :exec ":normal " . line("$") . "_ "
    " Move cursor to bottom
    :normal 1GG
    " Delete empty trailing line
    :normal dd
  endfunction
endif

" expand existing tabs
if !exists("*TabToSpaces")
  function TabToSpaces()
      retab
  :endfunction
endif

" from http://vim.wikia.com/wiki/Remove_unwanted_spaces
if !exists("*TrimWhiteSpace")
  function TrimWhiteSpace()
    %s/\s*$//
    ''
  :endfunction
endif

" map <leader>9 :!hash_syntax --to-19 %
nmap <leader>9 :%s/:\([^ ]*\)\(\s*\)=>/\1:/g<cr>

" Rspec
function! GuessRspecCommand()
  let g:haszeus = glob("`find . -name .zeus.sock`")

  if g:haszeus != ''
    return 'call Send_to_Tmux("zeus test {spec}\n")'
  else
    return 'call Send_to_Tmux("rspec {spec}\n")'
  endif
endfunction

let g:rspec_command = GuessRspecCommand()
map <leader>t :call RunCurrentSpecFile()<CR>
map <leader>s :call RunNearestSpec()<CR>
map <leader>l :call RunLastSpec()<CR>

" rails migrations
map <leader>rm :call Migrate()<CR>
map <leader>rrm :call Remigrate()<CR>

function! Remigrate()
  if InEngine()
    execute ":!rake db:drop db:create db:migrate && RAILS_ENV=test rake db:drop db:create db:migrate"
  else
    execute ":!rake db:drop db:create db:migrate db:test:prepare"
  endif
endfunction

function! Migrate()
  if InEngine()
    execute ":!rake db:migrate && RAILS_ENV=test rake db:migrate"
  else
    execute ":!rake db:migrate db:test:prepare"
  endif
endfunction

function! InEngine()
  let g:gemspec = glob("`find . -name \*.gemspec`")
  return g:gemspec != ""
endfunction
