fun! SetupCommandAlias(from, to)
  exec 'cnoreabbrev <expr> '.a:from
    \ .' ((getcmdtype() is# ":" && getcmdline() is# "'.a:from.'")'
    \ .'? ("'.a:to.'") : ("'.a:from.'"))'
endfun

call SetupCommandAlias("W","w")
call SetupCommandAlias("E","e")
