"########################################################################
" test_formatting.vim — Formatting and Timestamp update tests
"########################################################################

function! Test_timestamp_update_on_save() abort
  let l:dir = Vf90Fixture('timestamp')
  let l:file = l:dir . '/time.f90'
  let l:lines = [
        \ '! Last Modified: Mon Jan  1 00:00:00 2000',
        \ 'program timestamp_test',
        \ 'end program timestamp_test',
        \ ]
  call Vf90OpenScratch(l:file, l:lines)
  setlocal filetype=fortran

  " Trigger write
  silent write
  let l:saved_lines = readfile(l:file)
  call assert_notequal('! Last Modified: Mon Jan  1 00:00:00 2000', l:saved_lines[0])
  call assert_match('^! Last Modified:', l:saved_lines[0])
endfunction

function! Test_format_command_exists() abort
  let l:dir = Vf90Fixture('format_cmd')
  call Vf90OpenScratch(l:dir . '/fmt.f90', ['program fmt', 'end program fmt'])
  setlocal filetype=fortran
  call assert_equal(2, exists(':FortranFormat'))
  call assert_equal(2, exists(':FortranInstallDeps'))
endfunction
