"########################################################################
" test_deps.vim — Dependency checker tests
"########################################################################

function! Test_check_deps_runs_cleanly() abort
  " In advisory mode (arg=0), check_deps should return 0 or 1 without error
  let l:res = install_deps#check_deps(0)
  call assert_true(l:res == 0 || l:res == 1)
endfunction
