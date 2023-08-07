function! myspacevim#after() abort
  set scrolloff=8
  set listchars=trail:•
  set list

  " NOTE: Syncs the system clipboard with the default register
  if has('unix') && !has('mac')
    set clipboard=unnamedplus
  else
    set clipboard=unnamed
  endif
endfunction
