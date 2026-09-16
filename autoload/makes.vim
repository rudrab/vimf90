"########################################################################
" Filename:      autoload/makes.vim
" Copyright:     Copyright (C) 2020-2026 Rudra Banerjee
" License:       GPLv3
" Description:   Compilation, linking, execution, and project utilities for Fortran
"                Includes asynchronous build engine for Vim 8, Vim 9, and Neovim
"########################################################################

let s:save_cpo = &cpo
set cpo&vim

function! makes#get_opt(name, default) abort
  if exists('b:' . a:name)
    return get(b:, a:name)
  endif
  return get(g:, a:name, a:default)
endfunction

" Compiler errorformat resolution {{{1
function! s:get_errorformat(compiler) abort
  if a:compiler =~? 'ifort\|ifx'
    return '%f(%l): %trror #%n: %m,%f(%l): %twarning #%n: %m,%f(%l): %tremark #%n: %m'
  elseif a:compiler =~? 'nvfortran\|flang'
    return '%f:%l:%c: %trror: %m,%f:%l:%c: %twarning: %m,%f:%l:%c: %m'
  else
    " Standard modern gfortran errorformat
    return '%A%f:%l:%c:,%C%p%*[0123456789^],%Z%trror: %m,%Z%twarning: %m,%C%.%#,%f:%l:%c: %m'
  endif
endfunction
"}}}1

" Asynchronous Job Callbacks {{{1
let s:current_job = v:null

function! s:on_job_out(ctx, lines) abort
  for l:line in a:lines
    if !empty(l:line)
      call add(a:ctx.output, l:line)
    endif
  endfor
endfunction

function! s:on_job_exit(ctx, status) abort
  let l:saved_efm = &errorformat
  try
    let &errorformat = a:ctx.efm
    call setqflist([], 'r', {'title': a:ctx.title, 'lines': a:ctx.output})
  finally
    let &errorformat = l:saved_efm
  endtry

  redraw!
  let l:success = (a:status == 0)
  if l:success
    echomsg a:ctx.success_msg
    if get(g:, 'fortran_qf_auto_close', 1)
      cclose
    endif
  else
    echohl ErrorMsg | echo a:ctx.fail_msg . ' (exit code ' . a:status . ')' | echohl None
    botright cwindow
  endif

  if !empty(a:ctx.on_finish)
    call call(a:ctx.on_finish, [l:success])
  endif
endfunction

function! s:run_async_job(cmd, opts) abort
  let l:title       = get(a:opts, 'title', 'Fortran Build')
  let l:success_msg = get(a:opts, 'success_msg', 'Build finished successfully.')
  let l:fail_msg    = get(a:opts, 'fail_msg', 'Build failed.')
  let l:efm         = get(a:opts, 'efm', s:get_errorformat(makes#get_opt('fortran_compiler', 'gfortran')))
  let l:on_finish   = get(a:opts, 'on_finish', v:null)

  " Clear QuickFix list before starting
  call setqflist([], 'r', {'title': l:title, 'items': []})

  let l:context = {
        \ 'output': [],
        \ 'title': l:title,
        \ 'success_msg': l:success_msg,
        \ 'fail_msg': l:fail_msg,
        \ 'efm': l:efm,
        \ 'on_finish': l:on_finish,
        \ }

  " Neovim async execution
  if has('nvim')
    let l:callbacks = {
          \ 'on_stdout': {j, d, e -> s:on_job_out(l:context, d)},
          \ 'on_stderr': {j, d, e -> s:on_job_out(l:context, d)},
          \ 'on_exit':   {j, s, e -> s:on_job_exit(l:context, s)},
          \ }
    let s:current_job = jobstart(a:cmd, l:callbacks)
    return 1

  " Vim 8/9 async execution
  elseif has('job') && has('channel')
    let l:callbacks = {
          \ 'out_cb':   {c, msg -> s:on_job_out(l:context, [msg])},
          \ 'err_cb':   {c, msg -> s:on_job_out(l:context, [msg])},
          \ 'exit_cb':  {j, status -> s:on_job_exit(l:context, status)},
          \ 'mode':     'nl',
          \ }
    let s:current_job = job_start(a:cmd, l:callbacks)
    return 1

  " Synchronous fallback
  else
    return 0
  endif
endfunction
"}}}1

" Compile current buffer to object file {{{1
function! makes#Fcompile(...) abort
  let l:compiler = makes#get_opt('fortran_compiler', 'gfortran')
  let l:fcflags  = makes#get_opt('fortran_fcflags', '-Wall -O0 -c')
  let l:objext   = makes#get_opt('fortran_objExt', '.o')
  let l:is_async = a:0 > 0 ? a:1 : makes#get_opt('fortran_async', 1)

  let l:sou = expand('%:p')
  if empty(l:sou)
    echohl WarningMsg | echo 'No file name for current buffer.' | echohl None
    return 0
  endif

  let l:obj = expand('%:p:r') . l:objext

  " Check if target is already up-to-date
  if filereadable(l:obj) && (getftime(l:obj) >= getftime(l:sou))
    echomsg "'" . l:obj . "' is up to date."
    let s:fortran_comp_success = 1
    return 1
  endif

  silent update
  cclose

  let l:cmd_list = [l:compiler] + split(l:fcflags) + [l:sou, '-o', l:obj]
  let l:efm = s:get_errorformat(l:compiler)

  " Attempt async build
  if l:is_async && (has('job') || has('nvim'))
    echon 'Compiling ' . expand('%:t') . ' (async)...'
    let l:opts = {
          \ 'title': 'Fortran Compile: ' . expand('%:t'),
          \ 'success_msg': "'" . l:obj . "': Compiled successfully.",
          \ 'fail_msg': 'Compilation failed for ' . expand('%:t'),
          \ 'efm': l:efm,
          \ }
    return s:run_async_job(l:cmd_list, l:opts)
  endif

  " Synchronous compilation fallback
  let l:makeprg_saved = &l:makeprg
  let l:efm_saved     = &l:errorformat
  try
    let &l:makeprg = l:compiler
    let &l:errorformat = l:efm
    echon 'Compiling ' . expand('%:t') . ' ...'
    execute 'silent make! ' . l:fcflags . ' ' . fnameescape(l:sou) . ' -o ' . fnameescape(l:obj)
    redraw!

    if v:shell_error == 0
      echomsg "'" . l:obj . "': Compiled successfully."
      let s:fortran_comp_success = 1
      return 1
    else
      echohl ErrorMsg | echo 'Compilation failed with error code ' . v:shell_error | echohl None
      let s:fortran_comp_success = 0
      botright cwindow
      return 0
    endif
  finally
    let &l:makeprg     = l:makeprg_saved
    let &l:errorformat = l:efm_saved
  endtry
endfunction
"}}}1

" Generate executable {{{1
function! makes#Fexe(...) abort
  let l:compiler = makes#get_opt('fortran_compiler', 'gfortran')
  let l:flflags  = makes#get_opt('fortran_flflags', '-Wall -O0')
  let l:exeext   = makes#get_opt('fortran_exeExt', '')
  let l:is_async = a:0 > 0 ? a:1 : makes#get_opt('fortran_async', 1)
  let l:on_finish = a:0 > 1 ? a:2 : v:null

  let l:sou = expand('%:p')
  if empty(l:sou)
    echohl WarningMsg | echo 'No file name for current buffer.' | echohl None
    return 0
  endif

  let l:exe = expand('%:p:r') . l:exeext
  let s:exe = l:exe

  silent update
  cclose

  let l:cmd_list = [l:compiler] + split(l:flflags) + [l:sou, '-o', l:exe]
  let l:efm = s:get_errorformat(l:compiler)

  if l:is_async && (has('job') || has('nvim'))
    echon 'Building executable ' . fnamemodify(l:exe, ':t') . ' (async)...'
    let l:opts = {
          \ 'title': 'Fortran Link: ' . fnamemodify(l:exe, ':t'),
          \ 'success_msg': "'" . l:exe . "': Successfully linked.",
          \ 'fail_msg': 'Build failed for ' . fnamemodify(l:exe, ':t'),
          \ 'efm': l:efm,
          \ 'on_finish': l:on_finish,
          \ }
    return s:run_async_job(l:cmd_list, l:opts)
  endif

  " Synchronous build fallback
  let l:makeprg_saved = &l:makeprg
  let l:efm_saved     = &l:errorformat
  try
    let &l:makeprg = l:compiler
    let &l:errorformat = l:efm
    echon 'Building executable ' . fnamemodify(l:exe, ':t') . ' ...'
    execute 'silent make! ' . l:flflags . ' ' . fnameescape(l:sou) . ' -o ' . fnameescape(l:exe)
    redraw!

    if v:shell_error == 0
      echomsg "'" . l:exe . "': Successfully linked."
      let s:fortran_link_success = 1
      if !empty(l:on_finish)
        call call(l:on_finish, [1])
      endif
      return 1
    else
      echohl ErrorMsg | echo 'Build failed with error code ' . v:shell_error | echohl None
      let s:fortran_link_success = 0
      botright cwindow
      if !empty(l:on_finish)
        call call(l:on_finish, [0])
      endif
      return 0
    endif
  finally
    let &l:makeprg     = l:makeprg_saved
    let &l:errorformat = l:efm_saved
  endtry
endfunction
"}}}1

" Run executable {{{1
function! s:execute_binary(exe_path) abort
  if !filereadable(a:exe_path)
    echohl ErrorMsg | echo 'Executable not found: ' . a:exe_path | echohl None
    return
  endif

  let l:args = exists('b:Clargs') && !empty(b:Clargs) ? (' ' . b:Clargs) : ''

  if makes#get_opt('fortran_run_terminal', 0)
    if has('nvim')
      execute 'botright split | terminal ' . fnameescape(a:exe_path) . l:args
    elseif exists(':terminal') == 2
      execute 'botright terminal ' . fnameescape(a:exe_path) . l:args
    else
      execute '!' . fnameescape(a:exe_path) . l:args
    endif
  else
    echo 'Running ' . a:exe_path . l:args . ' ...'
    execute '!' . fnameescape(a:exe_path) . l:args
  endif
endfunction

function! makes#Frun() abort
  let l:exeext = makes#get_opt('fortran_exeExt', '')
  let l:exe    = expand('%:p:r') . l:exeext
  let s:exe    = l:exe

  " Compile synchronously first to ensure fresh executable before running
  let l:built = makes#Fexe(0)
  if l:built
    call s:execute_binary(s:exe)
  endif
endfunction
"}}}1

" Command Line Arguments {{{1
function! makes#Cla() abort
  let l:exeext = makes#get_opt('fortran_exeExt', '')
  let l:exe    = expand('%:p:t:r') . l:exeext
  if empty(l:exe)
    echohl WarningMsg | echo 'No file name for current buffer.' | echohl None
    return
  endif
  let l:prompt  = 'Command line arguments for "' . l:exe . '": '
  let l:current = exists('b:Clargs') ? b:Clargs : ''
  let b:Clargs  = input(l:prompt, l:current, 'file')
endfunction
"}}}1

" Debugger (gdb, lldb, etc.) {{{1
function! makes#Fdbg() abort
  let l:debugger = makes#get_opt('F_Debugger', 'gdb')
  if !executable(l:debugger)
    echohl ErrorMsg | echo 'Debugger "' . l:debugger . '" is not executable or not in PATH.' | echohl None
    return
  endif

  let l:exeext = makes#get_opt('fortran_exeExt', '')
  let l:exe    = expand('%:p:r') . l:exeext
  let s:exe    = l:exe

  " Compile with -g debug flags synchronously
  let l:orig_flflags = get(b:, 'fortran_flflags', get(g:, 'fortran_flflags', ''))
  let b:fortran_flflags = '-Wall -g -O0'
  let l:built = makes#Fexe(0)
  if !empty(l:orig_flflags)
    let b:fortran_flflags = l:orig_flflags
  else
    unlet! b:fortran_flflags
  endif

  if !l:built
    return
  endif

  let l:arguments = exists('b:Clargs') && !empty(b:Clargs) ? (' ' . b:Clargs) : ''
  redraw!

  if makes#get_opt('fortran_run_terminal', 0) && (has('nvim') || exists(':terminal') == 2)
    if has('nvim')
      execute 'botright split | terminal ' . fnameescape(l:debugger) . ' ' . fnameescape(l:exe) . l:arguments
    else
      execute 'botright terminal ' . fnameescape(l:debugger) . ' ' . fnameescape(l:exe) . l:arguments
    endif
  else
    echo 'Starting debugger: ' . l:debugger . ' ' . l:exe . l:arguments
    execute '!' . fnameescape(l:debugger) . ' ' . fnameescape(l:exe) . l:arguments
  endif
endfunction
"}}}1

" Run Makefile {{{1
function! makes#MakeRun() abort
  silent update
  cclose
  let l:margs = exists('b:MakeArgs') && !empty(b:MakeArgs) ? (' ' . b:MakeArgs) : ''
  execute 'make' . l:margs
  botright cwindow
endfunction
"}}}1

" Make arguments / properties {{{1
function! makes#MakeCla() abort
  let l:prompt  = 'Make parameters/target: '
  let l:current = exists('b:MakeArgs') ? b:MakeArgs : ''
  let b:MakeArgs = input(l:prompt, l:current)
endfunction
"}}}1

" Create standard project structure {{{1
function! makes#MakeProj() abort
  let l:prdir = input('Create new project directory: ', getcwd() . '/', 'dir')
  if empty(l:prdir)
    return
  endif

  let l:prdir = fnamemodify(l:prdir, ':p')
  if !isdirectory(l:prdir)
    call mkdir(l:prdir, 'p')
  endif

  call mkdir(l:prdir . '/help', 'p')
  call mkdir(l:prdir . '/src', 'p')

  for l:fname in ['ChangeLog', 'README.md', 'LICENSE', 'Makefile']
    let l:fpath = l:prdir . '/' . l:fname
    if !filereadable(l:fpath)
      call writefile([], l:fpath)
    endif
  endfor

  let l:cbf = expand('%:t')
  if !empty(l:cbf) && filereadable(expand('%:p'))
    silent execute '!mv ' . fnameescape(expand('%:p')) . ' ' . fnameescape(l:prdir . '/src/' . l:cbf)
    execute 'bdelete! | edit ' . fnameescape(l:prdir . '/src/' . l:cbf)
  endif

  echomsg 'Project structure created at: ' . l:prdir
endfunction
"}}}1

let &cpo = s:save_cpo
unlet s:save_cpo
