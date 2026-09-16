"########################################################################
" test_repl.vim — the interactive REPL terminal.
"
" 'cat' stands in for lfortran: it stays alive until killed, which is all these
" tests need from a REPL process.
"########################################################################

function! s:need_terminal() abort
  if !has('terminal') && !has('nvim')
    call Vf90Skip('no terminal support')
  endif
  call Vf90NeedExecutable('cat')
  let g:fortran_repl_command = 'cat'
endfunction

function! s:terminal_buffers() abort
  let l:bufs = []
  for l:b in range(1, bufnr('$'))
    if bufexists(l:b) && getbufvar(l:b, '&buftype') ==# 'terminal'
      call add(l:bufs, l:b)
    endif
  endfor
  return l:bufs
endfunction

function! Test_open_starts_a_repl() abort
  call s:need_terminal()
  let l:buf = repl#open()
  try
    call assert_equal(1, repl#is_active())
    call assert_equal(l:buf, repl#get_bufnr())
    call assert_equal(1, len(s:terminal_buffers()))
  finally
    call repl#restart()
  endtry
endfunction

function! Test_open_twice_reuses_the_session() abort
  call s:need_terminal()
  let l:first = repl#open()
  let l:second = repl#open()
  call assert_equal(l:first, l:second, 'a second open must not spawn another REPL')
  call assert_equal(1, len(s:terminal_buffers()))
endfunction

" close() only puts the window away: :close refuses a terminal whose job is
" running (E948), and the session is meant to survive for the next send.
function! Test_close_hides_without_killing() abort
  call s:need_terminal()
  let l:buf = repl#open()
  call repl#close()
  call assert_equal(1, repl#is_active(), 'close must not end the session')
  call assert_equal(l:buf, repl#get_bufnr())
  call assert_equal([], win_findbuf(l:buf), 'window should be gone')
endfunction

function! Test_toggle_hides_then_shows() abort
  call s:need_terminal()
  let l:buf = repl#open()
  call repl#toggle()
  call assert_equal([], win_findbuf(l:buf), 'hidden')
  call repl#toggle()
  call assert_notequal([], win_findbuf(repl#get_bufnr()), 'shown again')
  call assert_equal(1, repl#is_active())
endfunction

" Restarting must replace the session, not stack up windows and processes.
function! Test_restart_replaces_the_session() abort
  call s:need_terminal()
  let l:first = repl#open()
  call repl#restart()
  let l:second = repl#get_bufnr()
  call assert_notequal(l:first, l:second, 'a new session should have started')
  call assert_equal(1, repl#is_active())
  call assert_equal(1, len(s:terminal_buffers()), 'old terminal was left behind')
  call assert_equal(0, bufexists(l:first), 'old buffer was not disposed of')
endfunction

function! Test_repeated_restarts_do_not_accumulate() abort
  call s:need_terminal()
  call repl#open()
  for l:i in range(3)
    call repl#restart()
  endfor
  call assert_equal(1, len(s:terminal_buffers()), 'terminals accumulated')
  call assert_equal(2, winnr('$'), 'windows accumulated')
  call assert_equal(1, repl#is_active())
endfunction

" The exit callback must recognise which session ended, or it clears the
" handles of the replacement and orphans it.
function! Test_restart_keeps_handles_consistent() abort
  call s:need_terminal()
  call repl#open()
  call repl#restart()
  sleep 300m
  call assert_equal(1, repl#is_active(), 'handles were cleared by the old session')
  call assert_notequal(-1, repl#get_bufnr())
endfunction

" ---------------------------------------------------------------------------
" Sending text
" ---------------------------------------------------------------------------
function! Test_send_range_sends_every_line() abort
  call s:need_terminal()
  let l:dir = Vf90Fixture('repl')
  call Vf90OpenScratch(l:dir . '/lines.f90', ['l1', 'l2', 'l3', 'l4', 'l5'])
  let l:msg = execute('call repl#send_range(2, 4)')
  call assert_match('3 line', l:msg, 'expected three lines to be sent')
endfunction

" :'<,'> sets the command range, which reaches the function through its
" range attribute; a :<C-U> in the mapping would have deleted it.
function! Test_send_visual_uses_the_selected_range() abort
  call s:need_terminal()
  let l:dir = Vf90Fixture('repl')
  call Vf90OpenScratch(l:dir . '/lines.f90', ['l1', 'l2', 'l3', 'l4', 'l5'])
  let l:msg = execute('2,4call repl#send_visual()')
  call assert_match('3 line', l:msg, 'the range was lost on the way in')
endfunction

function! Test_send_subprogram_sends_enclosing_unit() abort
  call s:need_terminal()
  let l:dir = Vf90Fixture('repl')
  call Vf90OpenScratch(l:dir . '/s.f90', [
        \ 'module m',
        \ 'contains',
        \ '  real function square(x)',
        \ '    real :: x',
        \ '    square = x*x',
        \ '  end function square',
        \ 'end module m'])
  call cursor(4, 1)
  let l:msg = execute('call repl#send_subprogram()')
  call assert_match('lines 3-6', l:msg, 'expected the whole function, start to end')
endfunction

function! Test_send_opens_a_repl_when_none_is_running() abort
  call s:need_terminal()
  call assert_equal(0, repl#is_active(), 'precondition: nothing running')
  call repl#send(['print *, 1'])
  call assert_equal(1, repl#is_active(), 'send should have started a REPL')
endfunction
