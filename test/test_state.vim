"########################################################################
" test_state.vim — unified buffer state object (b:vimf90) tests
"########################################################################

function! Test_state_init_creates_b_vimf90() abort
  let l:dir = Vf90Fixture('state')
  call Vf90OpenScratch(l:dir . '/a.f90', ['program a', 'end program a'])
  setlocal filetype=fortran
  call assert_true(exists('b:vimf90'), 'b:vimf90 should be created on ft=fortran')
  call assert_equal(v:t_dict, type(b:vimf90), 'b:vimf90 should be a dictionary')
endfunction

function! Test_state_get_prefers_buffer_dict() abort
  let l:dir = Vf90Fixture('state')
  call Vf90OpenScratch(l:dir . '/a.f90', ['program a', 'end program a'])
  setlocal filetype=fortran
  let g:fortran_compiler = 'gfortran'
  call state#set('compiler', 'nvfortran')
  call assert_equal('nvfortran', state#get('compiler'))
  call assert_equal('nvfortran', profiles#get_compiler())
endfunction

function! Test_state_get_falls_back_to_legacy_buffer_var() abort
  let l:dir = Vf90Fixture('state')
  call Vf90OpenScratch(l:dir . '/a.f90', ['program a', 'end program a'])
  unlet! b:vimf90
  let b:fortran_compiler = 'ifx'
  let g:fortran_compiler = 'gfortran'
  call assert_equal('ifx', state#get('compiler'))
endfunction

function! Test_state_get_falls_back_to_global_var() abort
  let l:dir = Vf90Fixture('state')
  call Vf90OpenScratch(l:dir . '/a.f90', ['program a', 'end program a'])
  unlet! b:vimf90
  unlet! b:fortran_compiler
  let g:fortran_compiler = 'flang'
  call assert_equal('flang', state#get('compiler'))
endfunction

function! Test_state_get_falls_back_to_defaults() abort
  let l:dir = Vf90Fixture('state')
  call Vf90OpenScratch(l:dir . '/a.f90', ['program a', 'end program a'])
  unlet! b:vimf90
  unlet! b:fortran_compiler
  unlet! g:fortran_compiler
  call assert_equal('gfortran', state#get('compiler'))
  call assert_equal('debug', state#get('profile'))
endfunction

function! Test_state_set_updates_b_vimf90() abort
  let l:dir = Vf90Fixture('state')
  call Vf90OpenScratch(l:dir . '/a.f90', ['program a', 'end program a'])
  setlocal filetype=fortran
  call state#set('profile', 'release')
  call assert_equal('release', b:vimf90.profile)
  call assert_equal('release', state#get('profile'))
endfunction

function! Test_state_is_checks_truthiness() abort
  let l:dir = Vf90Fixture('state')
  call Vf90OpenScratch(l:dir . '/a.f90', ['program a', 'end program a'])
  setlocal filetype=fortran
  call state#set('openmp', 0)
  call assert_equal(0, state#is('openmp'))
  call state#set('openmp', 1)
  call assert_equal(1, state#is('openmp'))
  call state#set('gpu', '')
  call assert_equal(0, state#is('gpu'))
  call state#set('gpu', 'nvidia')
  call assert_equal(1, state#is('gpu'))
endfunction

function! Test_state_snapshot_merges_layers() abort
  let l:dir = Vf90Fixture('state')
  call Vf90OpenScratch(l:dir . '/a.f90', ['program a', 'end program a'])
  setlocal filetype=fortran
  let g:fortran_profile = 'fast'
  call state#set('compiler', 'ifort')
  let l:snap = state#snapshot()
  call assert_equal('ifort', l:snap.compiler)
  call assert_equal('fast', l:snap.profile)
endfunction

function! Test_state_cleanup_removes_b_vimf90() abort
  let l:dir = Vf90Fixture('state')
  call Vf90OpenScratch(l:dir . '/a.f90', ['program a', 'end program a'])
  setlocal filetype=fortran
  call assert_true(exists('b:vimf90'))
  call state#cleanup()
  call assert_false(exists('b:vimf90'))
endfunction

" Keys without a global must not borrow one by name. g:fortran_cla is the key
" that opens the arguments prompt, not the arguments.
function! Test_state_no_generic_global_fallback() abort
  let g:fortran_cla = '<leader>ca'
  try
    call assert_equal('', state#get('cla'), 'cla must not read the mapping variable')
    call assert_equal('FALLBACK', state#get('cla', 'FALLBACK'), 'the supplied default should win')
  finally
    unlet g:fortran_cla
  endtry
  " Keys that do have a global still read it.
  let g:fortran_compiler = 'ifx'
  try
    call assert_equal('ifx', state#get('compiler'))
  finally
    unlet g:fortran_compiler
  endtry
endfunction
