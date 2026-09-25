"########################################################################
" test_tagbar.vim — Tagbar & Symbol Outline Integration tests
"########################################################################

function! Test_tagbar_setup_registers_structure() abort
  unlet! g:tagbar_type_fortran
  call fortran_tagbar#setup()
  call assert_true(exists('g:tagbar_type_fortran'), 'tagbar_type_fortran should be registered')
  call assert_equal('fortran', g:tagbar_type_fortran.ctagstype)
  call assert_equal('%', g:tagbar_type_fortran.sro)

  " Check scope mappings
  call assert_equal('module', g:tagbar_type_fortran.kind2scope.m)
  call assert_equal('submodule', g:tagbar_type_fortran.kind2scope.s)
  call assert_equal('type', g:tagbar_type_fortran.kind2scope.t)
  call assert_equal('program', g:tagbar_type_fortran.kind2scope.p)
  call assert_equal('interface', g:tagbar_type_fortran.kind2scope.i)
endfunction
