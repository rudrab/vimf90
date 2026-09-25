"########################################################################
" test_scratch.vim — Instant Ephemeral Scientific Scratchpad tests
"########################################################################

function! Test_scratch_open_default_template() abort
  let l:buf = scratch#open()
  call assert_true(l:buf > 0, 'Scratch buffer should be created')
  call assert_equal('fortran', &filetype)
  call assert_equal('nofile', &buftype)

  let l:lines = getbufline(l:buf, 1, '$')
  call assert_match('program scratch', join(l:lines, "\n"))
  call assert_match('iso_fortran_env', join(l:lines, "\n"))

  " Close scratch buffer
  execute 'bwipeout! ' . l:buf
endfunction

function! Test_scratch_open_matrix_template() abort
  let l:buf = scratch#open('matrix')
  call assert_true(l:buf > 0)
  let l:lines = getbufline(l:buf, 1, '$')
  call assert_match('program scratch_matrix', join(l:lines, "\n"))
  call assert_match('matmul(A, B)', join(l:lines, "\n"))

  execute 'bwipeout! ' . l:buf
endfunction

function! Test_scratch_open_openmp_template() abort
  let l:buf = scratch#open('openmp')
  call assert_true(l:buf > 0)
  let l:lines = getbufline(l:buf, 1, '$')
  call assert_match('program scratch_openmp', join(l:lines, "\n"))
  call assert_match('omp_get_thread_num()', join(l:lines, "\n"))

  execute 'bwipeout! ' . l:buf
endfunction

function! Test_scratch_open_module_template() abort
  let l:buf = scratch#open('module')
  call assert_true(l:buf > 0)
  let l:lines = getbufline(l:buf, 1, '$')
  call assert_match('module scratch_mod', join(l:lines, "\n"))
  call assert_match('compute_energy', join(l:lines, "\n"))

  execute 'bwipeout! ' . l:buf
endfunction

function! Test_scratch_template_completion() abort
  let l:list = scratch#complete_template('', '', 0)
  call assert_true(index(l:list, 'program') >= 0)
  call assert_true(index(l:list, 'matrix') >= 0)
  call assert_true(index(l:list, 'openmp') >= 0)
  call assert_true(index(l:list, 'module') >= 0)
  call assert_true(index(l:list, 'test') >= 0)

  let l:filtered = scratch#complete_template('mat', '', 0)
  call assert_equal(['matrix'], l:filtered)
endfunction
