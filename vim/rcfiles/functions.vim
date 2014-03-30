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
map <leader>ra :call Rake()<CR>
map <leader>dra :call DevRake()<CR>
map <leader>pad :call AdHoc()<CR>
map <leader>rel :call AppRelease()<CR>
map <leader>zra :call ZeusRake()<CR>
map <leader>rm :call Migrate()<CR>
map <leader>rrm :call Remigrate()<CR>
map <leader>bun :call GoBundle()<CR>

function! ZeusRake()
  execute 'call Send_to_Tmux("zeus rake\n")'
endfunction

function! Rake()
  execute 'call Send_to_Tmux("rake\n")'
endfunction

function! DevRake()
  execute 'call Send_to_Tmux("reattach-to-user-namespace -l rake\n")'
endfunction

function! AdHoc()
  execute 'call Send_to_Tmux("reattach-to-user-namespace -l rake adhoc\n")'
endfunction

function! AppRelease()
  execute 'call Send_to_Tmux("reattach-to-user-namespace -l rake appstore\n")'
endfunction

function! GoBundle()
  execute 'call Send_to_Tmux("bundle install\n")'
endfunction

function! Remigrate()
  if InEngine()
    execute 'call Send_to_Tmux("rake db:drop db:create db:migrate && RAILS_ENV=test rake db:drop db:create db:migrate\n")'
  else
    execute 'call Send_to_Tmux("rake db:drop db:create db:migrate db:test:prepare\n")'
  endif
endfunction

function! Migrate()
  if InEngine()
    execute 'call Send_to_Tmux("rake db:migrate && RAILS_ENV=test rake db:migrate\n")'
  else
    execute 'call Send_to_Tmux("rake db:migrate db:test:prepare\n")'
  endif
endfunction

function! InEngine()
  let g:gemspec = glob("`find . -name \*.gemspec`")
  return g:gemspec != ""
endfunction

function! InMotion()
  let g:motionproj = system("grep RubyMotion Rakefile")
  return g:motionproj != ""
endfunction

" run the most recent command in the other pane
map <leader>ll :call Send_to_Tmux("!!\n\n")<CR>
map <leader>bc :call Send_to_Tmux("rubocop\n")<CR>
map <leader>bo :call Send_to_Tmux("rubocop ". expand('%:p') ."\n")<CR>
map <leader>cl :call Send_to_Tmux("clear\n")<CR>
map <leader>ex :call Send_to_Tmux("exit\n")<CR>

" dash
nmap <silent> <leader>d <Plug>DashGlobalSearch
