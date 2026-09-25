"########################################################################
" File:          autoload/repl.vim
" Author:        Rudra Banerjee (bnrj DOT rudra at gmail.com)
" License:       GPLv3
" Description:   Interactive LFortran REPL and Terminal Runner for Modern Fortran
"########################################################################

let s:save_cpo = &cpo
let &cpo = s:save_cpo

let s:repl_bufnr = -1
let s:repl_job   = -1
" Vim's exit_cb receives the job that ended, so the handle of the current
" session is kept to tell it apart from a session that has been replaced.
let s:repl_vim_job = v:null

function! repl#is_active() abort
  if s:repl_bufnr <= 0 || !bufexists(s:repl_bufnr)
    return 0
  endif

  if has('nvim')
    if s:repl_job <= 0
      return 0
    endif
    try
      return jobpid(s:repl_job) > 0
    catch
      return 0
    endtry
  elseif exists('*term_getstatus')
    return term_getstatus(s:repl_bufnr) !~# 'finished'
  else
    return 0
  endif
endfunction

function! repl#get_bufnr() abort
  return s:repl_bufnr
endfunction

function! s:on_repl_exit_nvim(job_id, data, event) abort
  if s:repl_job == a:job_id
    let s:repl_job = -1
    let s:repl_bufnr = -1
  endif
endfunction

function! s:on_repl_exit_vim(job, status) abort
  if s:repl_vim_job isnot v:null && a:job is s:repl_vim_job
    let s:repl_job = -1
    let s:repl_bufnr = -1
    let s:repl_vim_job = v:null
  endif
endfunction

function! repl#open(...) abort
  let l:cmd = a:0 > 0 && !empty(a:1) ? a:1 : get(g:, 'fortran_repl_command', 'lfortran')
  let l:split_cmd = get(g:, 'fortran_repl_split', 'botright 15split')
  let l:focus = get(g:, 'fortran_repl_focus', 0)
  let l:cur_win = win_getid()

  " Check executable
  let l:bin = split(l:cmd)[0]
  if !executable(l:bin)
    echohl WarningMsg
    echomsg 'vimf90: REPL binary "' . l:bin . '" not found in PATH.'
    echomsg 'Install LFortran (e.g. conda install lfortran -c conda-forge) or configure g:fortran_repl_command.'
    echohl None
  endif

  " If already active, check if window is visible
  if repl#is_active()
    let l:win_list = win_findbuf(s:repl_bufnr)
    if !empty(l:win_list)
      " Buffer is already displayed in a window
      if l:focus
        call win_gotoid(l:win_list[0])
      endif
      return s:repl_bufnr
    else
      " Buffer is running in background; open split and attach
      execute l:split_cmd
      execute 'buffer ' . s:repl_bufnr
      if !l:focus
        call win_gotoid(l:cur_win)
      endif
      return s:repl_bufnr
    endif
  endif

  " Start new terminal
  if has('nvim')
    execute l:split_cmd
    let s:repl_bufnr = bufnr('%')
    let s:repl_job = termopen(l:cmd, {
          \ 'on_exit': function('s:on_repl_exit_nvim')
          \ })
    setlocal nonumber norelativenumber bufhidden=wipe noswapfile
    setlocal filetype=fortran_repl
    if !l:focus
      call win_gotoid(l:cur_win)
    endif
    return s:repl_bufnr

  elseif has('terminal') || exists('*term_start')
    execute l:split_cmd
    let s:repl_bufnr = term_start(l:cmd, {
          \ 'curwin': 1,
          \ 'term_name': 'Fortran REPL (' . l:bin . ')',
          \ 'exit_cb': function('s:on_repl_exit_vim')
          \ })
    let s:repl_vim_job = s:repl_bufnr > 0 ? term_getjob(s:repl_bufnr) : v:null
    setlocal nonumber norelativenumber noswapfile
    if !l:focus
      call win_gotoid(l:cur_win)
    endif
    return s:repl_bufnr

  else
    echoerr 'vimf90: Terminal support (+terminal or Neovim) is required for REPL.'
    return -1
  endif
endfunction

function! repl#close() abort
  if s:repl_bufnr > 0 && bufexists(s:repl_bufnr)
    let l:win_list = win_findbuf(s:repl_bufnr)
    for l:win in l:win_list
      " 'hide' rather than 'close': Vim refuses to :close a terminal window
      " whose job is still running (E948), and the session is only being put
      " away here, not ended.
      if winnr('$') > 1
        silent! call win_execute(l:win, 'hide')
      else
        silent! call win_execute(l:win, 'enew')
      endif
    endfor
  endif
endfunction

" Close the window of a REPL buffer and dispose of it for good. Unlike
" repl#close(), which only hides a still-running session, this is used when the
" session is being replaced and must not be left behind.
function! s:terminate_bufnr(bufnr) abort
  if a:bufnr <= 0 || !bufexists(a:bufnr)
    return
  endif

  for l:win in win_findbuf(a:bufnr)
    if winnr('$') > 1
      silent! call win_execute(l:win, 'hide')
    else
      silent! call win_execute(l:win, 'enew')
    endif
  endfor

  if has('nvim')
    let l:job = getbufvar(a:bufnr, 'terminal_job_id', 0)
    if l:job > 0
      silent! call chanclose(l:job)
      silent! call jobstop(l:job)
    endif
  elseif !has('nvim') && exists('*term_getjob')
    let l:job = term_getjob(a:bufnr)
    if l:job isnot v:null && job_status(l:job) ==# 'run'
      call job_stop(l:job)
    endif
  endif

  if bufexists(a:bufnr)
    silent! execute 'bwipeout! ' . a:bufnr
  endif
endfunction

function! repl#toggle(...) abort
  let l:cmd = a:0 > 0 ? a:1 : ''
  if repl#is_active()
    let l:win_list = win_findbuf(s:repl_bufnr)
    if !empty(l:win_list)
      call repl#close()
      return
    endif
  endif
  call repl#open(l:cmd)
endfunction

function! repl#restart() abort
  if repl#is_active()
    " Detach the old session first so its exit callback cannot clear the
    " handles of the replacement REPL, but keep the handles locally so the
    " old window and process are still cleaned up below.
    let l:old_job = s:repl_job
    let l:old_buf = s:repl_bufnr
    let s:repl_bufnr = -1
    let s:repl_job = -1
    let s:repl_vim_job = v:null
    if has('nvim') && l:old_job > 0
      silent! call chanclose(l:old_job)
      silent! call jobstop(l:old_job)
    elseif exists('*term_sendkeys') && l:old_buf > 0
      call term_sendkeys(l:old_buf, "exit\<CR>")
    endif
    call s:terminate_bufnr(l:old_buf)
  else
    let s:repl_bufnr = -1
    let s:repl_job = -1
    let s:repl_vim_job = v:null
  endif
  call repl#open()
  echomsg 'vimf90: REPL restarted.'
endfunction

function! repl#send(input) abort
  if !repl#is_active()
    call repl#open()
    " Wait for the terminal to come up rather than guessing at a delay. A
    " fixed :sleep is a guess in both directions: too long on an idle machine,
    " too short on a loaded one. Worse, in a headless Neovim with nothing to
    " wake it, :sleep can block outright -- it hung the suite in CI once a
    " previous test had left a terminal channel open.
    if exists('*wait')
      call wait(2000, {-> repl#is_active()}, 10)
    endif
  endif

  let l:lines = []
  if type(a:input) == v:t_list
    let l:lines = a:input
  elseif type(a:input) == v:t_string
    let l:lines = split(a:input, "\n")
  else
    return
  endif

  if empty(l:lines)
    return
  endif

  if has('nvim')
    if s:repl_job > 0
      for l:line in l:lines
        call chansend(s:repl_job, l:line . "\n")
      endfor
    endif
  elseif exists('*term_sendkeys')
    if s:repl_bufnr > 0
      for l:line in l:lines
        call term_sendkeys(s:repl_bufnr, l:line . "\<CR>")
      endfor
    endif
  endif
endfunction

function! repl#send_line(...) abort
  let l:count = a:0 > 0 && a:1 > 0 ? a:1 : 1
  let l:start = line('.')
  let l:end   = min([line('$'), l:start + l:count - 1])
  let l:lines = getline(l:start, l:end)
  call repl#send(l:lines)
  " Flash sent lines brief feedback
  echomsg 'vimf90: Sent ' . len(l:lines) . ' line(s) to REPL.'
endfunction

function! repl#send_range(first, last) abort
  let l:lines = getline(a:first, a:last)
  if empty(l:lines)
    return
  endif
  call repl#send(l:lines)
  echomsg 'vimf90: Sent ' . len(l:lines) . ' line(s) to REPL.'
endfunction

function! repl#send_visual(...) range abort
  let l:first = a:0 > 0 ? a:1 : a:firstline
  let l:last  = a:0 > 1 ? a:2 : a:lastline
  call repl#send_range(l:first, l:last)
endfunction

function! repl#send_subprogram() abort
  " Try finding function/subroutine first
  let [l:start, l:end] = textobj#find_bounds('func')
  if l:start == 0 || l:end == 0
    " Try module/program
    let [l:start, l:end] = textobj#find_bounds('module')
  endif
  if l:start == 0 || l:end == 0
    " Try block/interface
    let [l:start, l:end] = textobj#find_bounds('block')
  endif

  if l:start == 0 || l:end == 0
    echohl WarningMsg
    echomsg 'vimf90: No enclosing Fortran subprogram, module, or block found.'
    echohl None
    return
  endif

  let l:lines = getline(l:start, l:end)
  call repl#send(l:lines)
  echomsg 'vimf90: Sent subprogram (lines ' . l:start . '-' . l:end . ') to REPL.'
endfunction

function! repl#send_buffer() abort
  let l:lines = getline(1, '$')
  if empty(l:lines)
    return
  endif
  call repl#send(l:lines)
  echomsg 'vimf90: Sent entire buffer (' . len(l:lines) . ' lines) to REPL.'
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
