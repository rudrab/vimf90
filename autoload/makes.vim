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
    return '%f(%l): %trror #%n: %m,%f(%l): %tarning #%n: %m,%f(%l): %temark #%n: %m'
  elseif a:compiler =~? 'nvfortran\|flang'
    return '%f:%l:%c: %trror: %m,%f:%l:%c: %tarning: %m,%f:%l:%c: %m'
  else
    " Standard modern gfortran errorformat
    return '%A%f:%l:%c:,%C%p%*[0123456789^],%Z%trror: %m,%Z%tarning: %m,%C%.%#,%f:%l:%c: %m'
  endif
endfunction
"}}}1

" QuickFix error validation helper {{{1
function! s:qf_has_errors() abort
  for l:item in getqflist()
    if l:item.valid && (l:item.type ==# 'E' || l:item.type ==# 'e' || empty(l:item.type))
      return 1
    endif
  endfor
  return 0
endfunction
"}}}1

" Asynchronous Job Callbacks {{{1
let s:current_job = v:null

function! makes#on_job_out(ctx, lines) abort
  if has('nvim')
    if empty(a:lines)
      return
    endif
    if !has_key(a:ctx, 'partial')
      let a:ctx.partial = ''
    endif
    let a:ctx.partial .= a:lines[0]
    if len(a:lines) > 1
      if !empty(a:ctx.partial)
        call add(a:ctx.output, a:ctx.partial)
      endif
      for l:i in range(1, len(a:lines) - 2)
        if !empty(a:lines[l:i])
          call add(a:ctx.output, a:lines[l:i])
        endif
      endfor
      let a:ctx.partial = a:lines[-1]
    endif
  else
    for l:line in a:lines
      if !empty(l:line)
        call add(a:ctx.output, l:line)
      endif
    endfor
  endif
endfunction

function! makes#on_job_exit(ctx, status) abort
  if has('nvim')
    if has_key(a:ctx, 'partial') && !empty(a:ctx.partial)
      call add(a:ctx.output, a:ctx.partial)
      let a:ctx.partial = ''
    endif
    call s:finish_job(a:ctx, a:status)
  else
    let a:ctx.status = a:status
    let a:ctx.exited = 1
    if get(a:ctx, 'closed', 0)
      call s:finish_job(a:ctx, a:ctx.status)
    endif
  endif
endfunction

function! makes#on_job_close(ctx) abort
  let a:ctx.closed = 1
  if get(a:ctx, 'exited', 0)
    call s:finish_job(a:ctx, get(a:ctx, 'status', 0))
  endif
endfunction

function! s:finish_job(ctx, status) abort
  let l:saved_efm = &errorformat
  try
    let &errorformat = a:ctx.efm
    call setqflist([], 'r', {'title': a:ctx.title, 'lines': a:ctx.output})
  finally
    let &errorformat = l:saved_efm
  endtry

  redraw!
  let l:success = (a:status == 0 && !s:qf_has_errors())
  if l:success
    echomsg a:ctx.success_msg
    if get(g:, 'fortran_qf_auto_close', 1)
      cclose
    endif
  else
    echohl ErrorMsg | echo a:ctx.fail_msg . (a:status != 0 ? ' (exit code ' . a:status . ')' : '') | echohl None
    botright cwindow
  endif

  if !empty(get(a:ctx, 'on_finish', v:null))
    call call(a:ctx.on_finish, [l:success])
  endif
endfunction

function! s:run_async_job(cmd, opts) abort
  let l:title       = get(a:opts, 'title', 'Fortran Build')
  let l:success_msg = get(a:opts, 'success_msg', 'Build finished successfully.')
  let l:fail_msg    = get(a:opts, 'fail_msg', 'Build failed.')
  let l:efm         = get(a:opts, 'efm', s:get_errorformat(makes#get_opt('fortran_compiler', 'gfortran')))
  let l:On_finish   = get(a:opts, 'on_finish', v:null)

  " Clear QuickFix list before starting
  call setqflist([], 'r', {'title': l:title, 'items': []})

  let l:context = {
        \ 'output': [],
        \ 'partial': '',
        \ 'title': l:title,
        \ 'success_msg': l:success_msg,
        \ 'fail_msg': l:fail_msg,
        \ 'efm': l:efm,
        \ 'on_finish': l:On_finish,
        \ }

  " Neovim async execution
  if has('nvim')
    let l:callbacks = {
          \ 'on_stdout': {j, d, e -> makes#on_job_out(l:context, d)},
          \ 'on_stderr': {j, d, e -> makes#on_job_out(l:context, d)},
          \ 'on_exit':   {j, s, e -> makes#on_job_exit(l:context, s)},
          \ }
    let s:current_job = jobstart(a:cmd, l:callbacks)
    return 1

  " Vim 8/9 async execution
  elseif has('job') && has('channel')
    let l:callbacks = {
          \ 'out_cb':   {c, msg -> makes#on_job_out(l:context, [msg])},
          \ 'err_cb':   {c, msg -> makes#on_job_out(l:context, [msg])},
          \ 'exit_cb':  {j, status -> makes#on_job_exit(l:context, status)},
          \ 'close_cb': {c -> makes#on_job_close(l:context)},
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
  let l:compiler = exists('b:fortran_compiler') ? b:fortran_compiler : profiles#get_effective_compiler()
  let l:fcflags  = makes#get_opt('fortran_fcflags', profiles#get_flags() . ' -c')
  let l:objext   = makes#get_opt('fortran_objExt', '.o')
  let l:is_async = a:0 > 0 ? a:1 : makes#get_opt('fortran_async', 1)

  " Multi-file project include directories
  let l:inc_dirs = project#get_include_dirs()
  let l:inc_flags_str = join(map(copy(l:inc_dirs), '"-I" . fnameescape(v:val)'), ' ')
  let l:inc_flags_list = map(copy(l:inc_dirs), '"-I" . v:val')

  if !empty(l:inc_flags_str)
    let l:fcflags_full = l:fcflags . ' ' . l:inc_flags_str
  else
    let l:fcflags_full = l:fcflags
  endif

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

  let l:cmd_list = [l:compiler] + split(l:fcflags) + l:inc_flags_list + [l:sou, '-o', l:obj]
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
    execute 'silent make! ' . l:fcflags_full . ' ' . fnameescape(l:sou) . ' -o ' . fnameescape(l:obj)
    redraw!

    if v:shell_error == 0 && !s:qf_has_errors()
      echomsg "'" . l:obj . "': Compiled successfully."
      let s:fortran_comp_success = 1
      return 1
    else
      echohl ErrorMsg | echo 'Compilation failed for ' . expand('%:t') | echohl None
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
  let l:compiler = exists('b:fortran_compiler') ? b:fortran_compiler : profiles#get_effective_compiler()
  let l:flflags  = makes#get_opt('fortran_flflags', profiles#get_flags())
  let l:exeext   = makes#get_opt('fortran_exeExt', '')
  let l:is_async = a:0 > 0 ? a:1 : makes#get_opt('fortran_async', 1)
  let l:On_finish = a:0 > 1 ? a:2 : v:null

  " Multi-file project include directories
  let l:inc_dirs = project#get_include_dirs()
  let l:inc_flags_str = join(map(copy(l:inc_dirs), '"-I" . fnameescape(v:val)'), ' ')
  let l:inc_flags_list = map(copy(l:inc_dirs), '"-I" . v:val')

  if !empty(l:inc_flags_str)
    let l:flflags_full = l:flflags . ' ' . l:inc_flags_str
  else
    let l:flflags_full = l:flflags
  endif

  let l:sou = expand('%:p')
  if empty(l:sou)
    echohl WarningMsg | echo 'No file name for current buffer.' | echohl None
    return 0
  endif

  let l:exe = expand('%:p:r') . l:exeext
  let s:exe = l:exe

  silent update
  cclose

  let l:cmd_list = [l:compiler] + split(l:flflags) + l:inc_flags_list + [l:sou, '-o', l:exe]
  let l:efm = s:get_errorformat(l:compiler)

  if l:is_async && (has('job') || has('nvim'))
    echon 'Building executable ' . fnamemodify(l:exe, ':t') . ' (async)...'
    let l:opts = {
          \ 'title': 'Fortran Link: ' . fnamemodify(l:exe, ':t'),
          \ 'success_msg': "'" . l:exe . "': Successfully linked.",
          \ 'fail_msg': 'Build failed for ' . fnamemodify(l:exe, ':t'),
          \ 'efm': l:efm,
          \ 'on_finish': l:On_finish,
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
    execute 'silent make! ' . l:flflags_full . ' ' . fnameescape(l:sou) . ' -o ' . fnameescape(l:exe)
    redraw!

    if v:shell_error == 0 && !s:qf_has_errors()
      echomsg "'" . l:exe . "': Successfully linked."
      let s:fortran_link_success = 1
      if !empty(l:On_finish)
        call call(l:On_finish, [1])
      endif
      return 1
    else
      echohl ErrorMsg | echo 'Build failed for ' . fnamemodify(l:exe, ':t') | echohl None
      let s:fortran_link_success = 0
      botright cwindow
      if !empty(l:On_finish)
        call call(l:On_finish, [0])
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

" Run Makefile (historical fallback) {{{1
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

let &cpo = s:save_cpo
unlet s:save_cpo
