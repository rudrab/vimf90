"########################################################################
" Filename:      autoload/fpm.vim
" Copyright:     Copyright (C) 2026 Rudra Banerjee
" License:       GPLv3
" Description:   Fortran Package Manager (fpm) integration for vimf90
"                Includes target discovery, test runner, and manifest helpers
"########################################################################

let s:save_cpo = &cpo
set cpo&vim

" Standard Scientific Fortran Dependencies Registry
let s:known_dependencies = {
      \ 'stdlib':        'stdlib = { git = "https://github.com/fortran-lang/stdlib.git" }',
      \ 'test-drive':    'test-drive = { git = "https://github.com/fortran-lang/test-drive.git" }',
      \ 'toml-f':        'toml-f = { git = "https://github.com/toml-f/toml-f.git" }',
      \ 'lapack':        'lapack = { git = "https://github.com/fortran-lang/lapack.git" }',
      \ 'json-fortran':  'json-fortran = { git = "https://github.com/jacobwilliams/json-fortran.git" }',
      \ 'mstore':        'mstore = { git = "https://github.com/fortran-lang/mstore.git" }',
      \ 'datetime':      'datetime-fortran = { git = "https://github.com/wavebitscientific/datetime-fortran.git" }',
      \ 'csv-fortran':   'fortran-csv-module = { git = "https://github.com/jacobwilliams/fortran-csv-module.git" }',
      \ }

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

" Discover available test targets from test/ directory {{{1
function! fpm#list_test_targets() abort
  let l:root = fpm#find_root()
  if empty(l:root) || !isdirectory(l:root . '/test')
    return []
  endif

  let l:files = globpath(l:root . '/test', '*.f90', 0, 1)
        \ + globpath(l:root . '/test', '*.F90', 0, 1)
        \ + globpath(l:root . '/test', '*.f', 0, 1)

  let l:targets = []
  for l:f in l:files
    call add(l:targets, fnamemodify(l:f, ':t:r'))
  endfor
  return sort(l:targets)
endfunction
"}}}1

" Discover available app targets from app/ directory {{{1
function! fpm#list_app_targets() abort
  let l:root = fpm#find_root()
  if empty(l:root) || !isdirectory(l:root . '/app')
    return []
  endif

  let l:files = globpath(l:root . '/app', '*.f90', 0, 1)
        \ + globpath(l:root . '/app', '*.F90', 0, 1)
        \ + globpath(l:root . '/app', '*.f', 0, 1)

  let l:targets = []
  for l:f in l:files
    call add(l:targets, fnamemodify(l:f, ':t:r'))
  endfor
  return sort(l:targets)
endfunction
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
  
  " Inject profile flags if not specified
  let l:flags_to_add = []
  if index(['build', 'run', 'test'], a:subcmd) >= 0 && a:args !~# '--profile'
    let l:prof = profiles#get_profile()
    if l:prof ==# 'release'
      call add(l:flags_to_add, '--profile')
      call add(l:flags_to_add, 'release')
    endif
  endif

  let l:cmd_list += l:flags_to_add
  if !empty(a:args)
    let l:cmd_list += split(a:args)
  endif

  let l:compiler = profiles#get_effective_compiler()
  let l:efm = '%A%f:%l:%c:,%C%p%*[0123456789^],%Z%trror: %m,%Z%tarning: %m,%C%.%#,%f:%l:%c: %m'

  silent update

  " Change directory context to project root
  let l:orig_dir = getcwd()
  try
    execute 'lcd ' . fnameescape(l:root)

    if l:is_async && (has('job') || has('nvim'))
      echon 'Running fpm ' . a:subcmd . ' in ' . fnamemodify(l:root, ':t') . ' (async)...'
      let l:On_finish = v:null
      if a:subcmd ==# 'build'
        let l:On_finish = {success -> success ? fortls#generate(l:root) : 0}
      endif
      let l:opts = {
            \ 'title': 'fpm ' . a:subcmd . ' (' . fnamemodify(l:root, ':t') . ')',
            \ 'success_msg': 'fpm ' . a:subcmd . ' completed successfully.',
            \ 'fail_msg': 'fpm ' . a:subcmd . ' failed.',
            \ 'efm': l:efm,
            \ 'on_finish': l:On_finish,
            \ }
      return s:run_async_in_dir(l:cmd_list, l:root, l:opts)
    else
      " Synchronous execution
      cclose
      let l:makeprg_saved = &l:makeprg
      let l:efm_saved     = &l:errorformat
      try
        let &l:makeprg = 'fpm'
        let &l:errorformat = l:efm
        let l:full_args = join(l:cmd_list[1:], ' ')
        execute 'silent make! ' . l:full_args
        redraw!
        if v:shell_error == 0 && !s:qf_has_errors()
          echomsg 'fpm ' . a:subcmd . ' completed successfully.'
          if a:subcmd ==# 'build'
            call fortls#generate(l:root)
          endif
          return 1
        else
          echohl ErrorMsg | echo 'fpm ' . a:subcmd . ' failed.' | echohl None
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
  let l:On_finish   = get(a:opts, 'on_finish', v:null)

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
          \ 'close_cb': {c -> makes#on_job_close(l:context)},
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
  if !empty(l:args) && l:args !~# '^-'
    " User passed target name directly, e.g. :FortranFpmTest test_solver
    let l:args = '--target ' . l:args
  endif
  return fpm#execute('test', l:args)
endfunction

" Run single unit test from active buffer {{{1
function! fpm#test_current() abort
  let l:root = fpm#find_root()
  if empty(l:root)
    echohl WarningMsg | echo 'vimf90: fpm.toml not found.' | echohl None
    return 0
  endif

  let l:cur_file = expand('%:p')
  let l:target = ''

  " If file is inside test/ directory, use filename as target
  if l:cur_file =~# '/test/'
    let l:target = expand('%:t:r')
  else
    " Scan buffer for program test_...
    let l:view = winsaveview()
    let l:match_line = search('\v^\s*program\s+\w+', 'nw')
    call winrestview(l:view)
    if l:match_line > 0
      let l:line_str = getline(l:match_line)
      let l:m = matchlist(l:line_str, '\v^\s*program\s+(\w+)')
      if !empty(l:m)
        let l:target = l:m[1]
      endif
    endif
  endif

  if empty(l:target)
    echohl WarningMsg | echo 'vimf90: Current buffer is not a recognized fpm test target. Running all tests...' | echohl None
    return fpm#test('')
  endif

  echomsg 'vimf90: Running fpm test target [' . l:target . ']...'
  return fpm#test('--target ' . l:target)
endfunction
"}}}1

function! fpm#run(...) abort
  let l:root = fpm#find_root()
  if empty(l:root)
    echohl WarningMsg | echo 'fpm.toml not found.' | echohl None
    return
  endif

  let l:args = a:0 > 0 ? a:1 : ''
  if !empty(l:args) && l:args !~# '^-'
    let l:args = '--target ' . l:args
  endif

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
    call fortls#generate(fnamemodify(l:pname, ':p'))
    let l:main_file = filereadable(l:pname . '/app/main.f90') ? l:pname . '/app/main.f90' : l:pname . '/src/' . l:pname . '.f90'
    execute 'edit ' . fnameescape(l:main_file)
    echomsg 'New fpm project "' . l:pname . '" initialized.'
  endif
endfunction

" Add standard dependency to fpm.toml manifest {{{1
function! fpm#add_dependency(dep_name) abort
  let l:root = fpm#find_root()
  if empty(l:root)
    echohl WarningMsg | echo 'vimf90: fpm.toml not found in project.' | echohl None
    return 0
  endif

  let l:manifest = l:root . '/fpm.toml'
  if !filereadable(l:manifest)
    echohl ErrorMsg | echo 'vimf90: Cannot read ' . l:manifest | echohl None
    return 0
  endif

  let l:dep = trim(tolower(a:dep_name))
  if empty(l:dep)
    echohl WarningMsg | echo 'vimf90: Specify dependency name (e.g. :FortranFpmAdd stdlib)' | echohl None
    return 0
  endif

  let l:snippet = get(s:known_dependencies, l:dep, '')
  if empty(l:snippet)
    " Custom git dependency or name
    let l:snippet = l:dep . ' = { git = "https://github.com/' . l:dep . '.git" }'
  endif

  let l:lines = readfile(l:manifest)
  let l:has_dep_header = 0
  let l:insert_idx = len(l:lines)

  for l:i in range(len(l:lines))
    if l:lines[l:i] =~# '^\s*\[dependencies\]'
      let l:has_dep_header = 1
      let l:insert_idx = l:i + 1
      break
    endif
  endfor

  if !l:has_dep_header
    call add(l:lines, '')
    call add(l:lines, '[dependencies]')
    call add(l:lines, l:snippet)
  else
    call insert(l:lines, l:snippet, l:insert_idx)
  endif

  call writefile(l:lines, l:manifest)
  echomsg 'vimf90: Added "' . l:dep . '" to ' . l:manifest
  return 1
endfunction
"}}}1

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
  elseif l:subcmd ==# 'add'
    call fpm#add_dependency(l:rest)
  else
    call fpm#execute(l:subcmd, l:rest)
  endif
endfunction

" Completion helpers
function! fpm#complete(arglead, cmdline, cursorpos) abort
  let l:tokens = split(a:cmdline)
  if len(l:tokens) >= 2 && l:tokens[1] ==# 'test'
    return fpm#complete_test_targets(a:arglead, a:cmdline, a:cursorpos)
  elseif len(l:tokens) >= 2 && l:tokens[1] ==# 'run'
    return fpm#complete_app_targets(a:arglead, a:cmdline, a:cursorpos)
  elseif len(l:tokens) >= 2 && l:tokens[1] ==# 'add'
    return fpm#complete_known_deps(a:arglead, a:cmdline, a:cursorpos)
  endif

  let l:subcommands = ['build', 'run', 'test', 'new', 'add', 'update', 'clean', 'install']
  return filter(l:subcommands, 'v:val =~ "^" . a:arglead')
endfunction

function! fpm#complete_test_targets(arglead, cmdline, cursorpos) abort
  let l:targets = fpm#list_test_targets()
  return filter(l:targets, 'v:val =~ "^" . a:arglead')
endfunction

function! fpm#complete_app_targets(arglead, cmdline, cursorpos) abort
  let l:targets = fpm#list_app_targets()
  return filter(l:targets, 'v:val =~ "^" . a:arglead')
endfunction

function! fpm#complete_known_deps(arglead, cmdline, cursorpos) abort
  let l:deps = keys(s:known_dependencies)
  return filter(l:deps, 'v:val =~ "^" . a:arglead')
endfunction
"}}}1

let &cpo = s:save_cpo
unlet s:save_cpo
