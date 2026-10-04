"########################################################################
" test_dap.vim — Scientific Debugging (DAP, Breakpoints, Matrix Inspector)
"########################################################################

function! Test_dap_toggle_breakpoint() abort
  let l:dir = Vf90Fixture('dap')
  call Vf90OpenScratch(l:dir . '/a.f90', ['program a', '  print *, "hello"', 'end program a'])
  setlocal filetype=fortran

  call cursor(2, 1)
  " Calling toggle_breakpoint should succeed without throwing
  call dap#toggle_breakpoint()
  call assert_equal(2, line('.'))
endfunction

function! Test_dap_inspect_array_creates_buffer() abort
  let l:dir = Vf90Fixture('dap_array')
  call Vf90OpenScratch(l:dir . '/a.f90', ['program a', '  real :: mat(4, 4)', 'end program a'])
  setlocal filetype=fortran

  call dap#inspect_array('mat', 4, 4)

  let l:found = 0
  for l:b in range(1, bufnr('$'))
    if bufexists(l:b) && bufname(l:b) =~# 'Fortran Array Inspector'
      let l:found = l:b
      break
    endif
  endfor

  call assert_true(l:found > 0, 'Array Inspector buffer should exist')
  let l:lines = getbufline(l:found, 1, '$')
  call assert_match('Scientific Fortran Array Inspector: mat', join(l:lines, "\n"))
  call assert_match('4 rows x 4 cols', join(l:lines, "\n"))

  execute 'bwipeout! ' . l:found
endfunction
