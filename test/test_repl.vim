"########################################################################
" test_repl.vim — the interactive REPL terminal.
"
" test/fixtures/bin/vf90-repl-stub stands in for lfortran: it echoes what it is
" given and stays alive until the job is stopped, which is all these tests need
" from a REPL. It is used rather than `cat` so that a process left behind by a
" wedged run is identifiable by name and can be cleaned up without any risk of
" hitting something unrelated on the machine.
"########################################################################

function! s:need_terminal() abort
  if !has('terminal') && !has('nvim')
    call Vf90Skip('no terminal support')
  endif
  let l:stub = Vf90ReplStub()
  if !executable(l:stub)
    call Vf90Skip('the REPL stub is not executable: ' . l:stub)
  endif
  let g:fortran_repl_command = l:stub
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

" A fixed-form program unit is bounded by a bare END, so the subprogram send
" must follow the fixed-form rules rather than looking for END SUBROUTINE.
function! Test_send_subprogram_handles_fixed_form() abort
  call s:need_terminal()
  let l:dir = Vf90Fixture('repl')
  call Vf90OpenScratch(l:dir . '/legacy.f', [
        \ '      PROGRAM MAIN',
        \ '      CALL SUB1',
        \ '      END',
        \ '      SUBROUTINE SUB1',
        \ '      WRITE(*,*) 1',
        \ '      END'])
  call cursor(5, 1)
  let l:msg = execute('call repl#send_subprogram()')
  call assert_match('lines 4-6', l:msg, 'expected the whole fixed-form subroutine')
endfunction

" ---------------------------------------------------------------------------
" The leak detector itself
"
" The suite reports a process it started and did not reap as a failure. That
" check is only worth having if it actually sees one, so this starts a stub
" outside the plugin's bookkeeping, proves the detector finds it, and cleans up.
" ---------------------------------------------------------------------------
function! Test_leak_detector_sees_an_unreaped_process() abort
  call s:need_terminal()
  if !executable('pgrep')
    call Vf90Skip('pgrep is not available')
  endif
  " Compare against whatever is running now rather than demanding a quiet
  " machine: a stray from an earlier aborted run would otherwise fail this.
  let l:before = Vf90LeakedProcesses(2000)

  let l:stub = Vf90ReplStub()
  if has('nvim')
    let l:job = jobstart([l:stub])
  else
    let l:job = job_start([l:stub])
  endif
  try
    " Poll for appearance rather than waiting out a grace period: the job is
    " started asynchronously, so it may take a moment to show up.
    call assert_equal(1, Vf90WaitFor({-> len(Vf90LeakedProcesses(0)) > len(l:before)}, 2000),
          \ 'an unreaped stub was not detected')
  finally
    if has('nvim')
      silent! call jobstop(l:job)
    else
      silent! call job_stop(l:job, 'kill')
    endif
    call Vf90KillLeaked()
  endtry
  call assert_equal(len(l:before), len(Vf90LeakedProcesses(2000)),
        \ 'cleanup left something behind')
endfunction

function! Test_send_opens_a_repl_when_none_is_running() abort
  call Vf90Mark('send_opens: need_terminal')
  call s:need_terminal()
  call Vf90Mark('send_opens: precondition')
  call assert_equal(0, repl#is_active(), 'precondition: nothing running')
  " silent, because this is the one send test that does not capture output
  " through execute(); an unsilenced message can raise the hit-enter prompt.
  call Vf90Mark('send_opens: about to send')
  silent call repl#send(['print *, 1'])
  call Vf90Mark('send_opens: sent, checking active')
  call assert_equal(1, repl#is_active(), 'send should have started a REPL')
  call Vf90Mark('send_opens: body done')
endfunction
