"########################################################################
" Filename:      autoload/fpm.vim
" Copyright:     Copyright (C) 2026 Rudra Banerjee
" License:       GPLv3
" Description:   Fortran Package Manager (fpm) integration for vimf90
"########################################################################

let s:save_cpo = &cpo
set cpo&vim

" Find fpm root directory containing fpm.toml {{{1
function! fpm#find_root(...) abort
  let l:start_dir = a:0 > 0 && !empty(a:1) ? a:1 : expand('%:p:h')
  if empty(l:start_dir)
    let l:start_dir = getcwd()
  endif

  let l:root = findfile('fpm.toml', l:start_dir . ';')
  if !empty(l:root)
    return fnamemodify(l:root, ':p:h')
  endif
  return ''
endfunction
"}}}1

" Run fpm command asynchronously or synchronously {{{1
function! fpm#execute(subcmd, args, ...) abort
  let l:root = fpm#find_root()
  if empty(l:root)
    echohl WarningMsg
    echomsg 'fpm.toml not found in current directory or any parent directories.'
    echomsg 'Run :FortranFpmNew <name> to create a new fpm project.'
    echohl None
    return 0
  endif

  if !executable('fpm')
    echohl ErrorMsg
    echo 'fpm (Fortran Package Manager) is not installed or not in PATH.'
    echo 'Visit https://fpm.fortran-lang.org/ for installation instructions.'
    echohl None
    return 0
  endif

  let l:is_async = a:0 > 0 ? a:1 : makes#get_opt('fortran_async', 1)
  let l:cmd_list = ['fpm', a:subcmd]
  if !empty(a:args)
    let l:cmd_list += split(a:args)
  endif

  let l:compiler = makes#get_opt('fortran_compiler', 'gfortran')
  let l:efm = '%A%f:%l:%c:,%C%p%*[0123456789^],%Z%trror: %m,%Z%twarning: %m,%C%.%#,%f:%l:%c: %m'

  silent update

  " Change directory context to project root
  let l:orig_dir = getcwd()
  try
    execute 'lcd ' . fnameescape(l:root)

    if l:is_async && (has('job') || has('nvim'))
      echon 'Running fpm ' . a:subcmd . ' in ' . fnamemodify(l:root, ':t') . ' (async)...'
      let l:opts = {
            \ 'title': 'fpm ' . a:subcmd . ' (' . fnamemodify(l:root, ':t') . ')',
            \ 'success_msg': 'fpm ' . a:subcmd . ' completed successfully.',
            \ 'fail_msg': 'fpm ' . a:subcmd . ' failed.',
            \ 'efm': l:efm,
            \ }
      " Delegate to async runner in makes.vim
      return s:run_async_in_dir(l:cmd_list, l:root, l:opts)
    else
      " Synchronous execution
      cclose
      let l:makeprg_saved = &l:makeprg
      let l:efm_saved     = &l:errorformat
      try
        let &l:makeprg = 'fpm'
        let &l:errorformat = l:efm
        execute 'silent make! ' . a:subcmd . ' ' . a:args
        redraw!
        if v:shell_error == 0
          echomsg 'fpm ' . a:subcmd . ' completed successfully.'
          return 1
        else
          echohl ErrorMsg | echo 'fpm ' . a:subcmd . ' failed with code ' . v:shell_error | echohl None
          botright cwindow
          return 0
        endif
      finally
        let &l:makeprg     = l:makeprg_saved
        let &l:errorformat = l:efm_saved
      endtry
    endif
  finally
    execute 'lcd ' . fnameescape(l:orig_dir)
  endtry
endfunction
"}}}1

" Helper to run async job inside specific directory {{{1
function! s:run_async_in_dir(cmd_list, dir, opts) abort
  let l:title       = get(a:opts, 'title', 'fpm')
  let l:success_msg = get(a:opts, 'success_msg', 'Finished.')
  let l:fail_msg    = get(a:opts, 'fail_msg', 'Failed.')
  let l:efm         = get(a:opts, 'efm', '')

  call setqflist([], 'r', {'title': l:title, 'items': []})

  let l:context = {
        \ 'output': [],
        \ 'title': l:title,
        \ 'success_msg': l:success_msg,
        \ 'fail_msg': l:fail_msg,
        \ 'efm': l:efm,
        \ }

  if has('nvim')
    let l:callbacks = {
          \ 'cwd': a:dir,
          \ 'on_stdout': {j, d, e -> makes#on_job_out(l:context, d)},
          \ 'on_stderr': {j, d, e -> makes#on_job_out(l:context, d)},
          \ 'on_exit':   {j, s, e -> makes#on_job_exit(l:context, s)},
          \ }
    call jobstart(a:cmd_list, l:callbacks)
    return 1
  elseif has('job') && has('channel')
    let l:callbacks = {
          \ 'cwd':      a:dir,
          \ 'out_cb':   {c, msg -> makes#on_job_out(l:context, [msg])},
          \ 'err_cb':   {c, msg -> makes#on_job_out(l:context, [msg])},
          \ 'exit_cb':  {j, status -> makes#on_job_exit(l:context, status)},
          \ 'mode':     'nl',
          \ }
    call job_start(a:cmd_list, l:callbacks)
    return 1
  endif
  return 0
endfunction
"}}}1

" User-facing fpm actions {{{1
function! fpm#build(...) abort
  let l:args = a:0 > 0 ? a:1 : ''
  return fpm#execute('build', l:args)
endfunction

function! fpm#test(...) abort
  let l:args = a:0 > 0 ? a:1 : ''
  return fpm#execute('test', l:args)
endfunction

function! fpm#run(...) abort
  let l:root = fpm#find_root()
  if empty(l:root)
    echohl WarningMsg | echo 'fpm.toml not found.' | echohl None
    return
  endif

  let l:args = a:0 > 0 ? a:1 : ''
  let l:orig_dir = getcwd()
  try
    execute 'lcd ' . fnameescape(l:root)
    if makes#get_opt('fortran_run_terminal', 0) && (has('nvim') || exists(':terminal') == 2)
      if has('nvim')
        execute 'botright split | terminal fpm run ' . l:args
      else
        execute 'botright terminal fpm run ' . l:args
      endif
    else
      echo 'Running fpm run ' . l:args . ' ...'
      execute '!fpm run ' . l:args
    endif
  finally
    execute 'lcd ' . fnameescape(l:orig_dir)
  endtry
endfunction

function! fpm#new(name) abort
  let l:pname = !empty(a:name) ? a:name : input('New fpm project name: ')
  if empty(l:pname)
    return
  endif

  if !executable('fpm')
    echohl ErrorMsg | echo 'fpm is not installed.' | echohl None
    return
  endif

  execute '!fpm new ' . fnameescape(l:pname)
  if isdirectory(l:pname)
    execute 'edit ' . fnameescape(l:pname . '/app/main.f90')
    echomsg 'New fpm project "' . l:pname . '" initialized.'
  endif
endfunction

function! fpm#command(args) abort
  let l:parts = split(a:args)
  if empty(l:parts)
    call fpm#build()
    return
  endif

  let l:subcmd = l:parts[0]
  let l:rest   = join(l:parts[1:], ' ')

  if l:subcmd ==# 'build'
    call fpm#build(l:rest)
  elseif l:subcmd ==# 'run'
    call fpm#run(l:rest)
  elseif l:subcmd ==# 'test'
    call fpm#test(l:rest)
  elseif l:subcmd ==# 'new'
    call fpm#new(l:rest)
  else
    call fpm#execute(l:subcmd, l:rest)
  endif
endfunction

function! fpm#complete(arglead, cmdline, cursorpos) abort
  let l:subcommands = ['build', 'run', 'test', 'new', 'update', 'clean', 'install']
  return filter(l:subcommands, 'v:val =~ "^" . a:arglead')
endfunction
"}}}1

let &cpo = s:save_cpo
unlet s:save_cpo
