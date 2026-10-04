"########################################################################
" test_profiles.vim — compiler presets, profiles and the HPC toggles.
"########################################################################

function! Test_default_profile_is_debug() abort
  call assert_equal('debug', profiles#get_profile())
  call assert_match('-O0', profiles#get_flags())
endfunction

function! Test_release_profile_flags() abort
  call profiles#set_profile('release')
  call assert_equal('release', profiles#get_profile())
  call assert_match('-O3', profiles#get_flags())
  call assert_notmatch('-O0', profiles#get_flags())
endfunction

function! Test_unknown_profile_is_rejected() abort
  call profiles#set_profile('release')
  silent! call profiles#set_profile('not_a_profile')
  call assert_notequal('not_a_profile', profiles#get_profile(),
        \ 'an unknown profile must not be adopted')
endfunction

function! Test_profile_presets_per_compiler() abort
  call profiles#set_compiler('gfortran')
  call assert_match('-fcheck=all', profiles#get_flags(), 'gfortran debug')
  call profiles#set_compiler('ifx')
  call assert_match('-check all', profiles#get_flags(), 'ifx debug')
endfunction

function! Test_extra_flags_are_appended() abort
  let g:fortran_extra_flags = '-DMY_MACRO'
  call assert_match('-DMY_MACRO', profiles#get_flags())
endfunction

function! Test_openmp_toggle() abort
  call assert_equal(0, profiles#is_openmp(), 'off by default')
  call profiles#toggle_openmp(1)
  call assert_equal(1, profiles#is_openmp())
  call assert_match('-fopenmp', profiles#get_flags())
  call profiles#toggle_openmp(0)
  call assert_equal(0, profiles#is_openmp())
  call assert_notmatch('-fopenmp', profiles#get_flags())
endfunction

function! Test_mpi_changes_effective_compiler() abort
  call profiles#set_compiler('gfortran')
  call assert_equal('gfortran', profiles#get_effective_compiler())
  call profiles#toggle_mpi(1)
  call assert_equal(1, profiles#is_mpi())
  call assert_match('mpi', profiles#get_effective_compiler(), 'MPI wrapper in use')
  call profiles#toggle_mpi(0)
  call assert_equal('gfortran', profiles#get_effective_compiler())
endfunction

" hpc.vim is a separate autoload file, so it is not loaded until something
" calls into it. Flags set in a vimrc must still take effect on the first
" build, before any :FortranGPU has been run.
function! Test_gpu_flags_apply_without_touching_hpc_first() abort
  let g:fortran_gpu = 'openmp'
  call assert_match('-fopenmp', profiles#get_flags(), 'GPU flags missing at startup')
  call assert_match('OPENMP', profiles#status(), 'status does not mention GPU')
endfunction

function! Test_gpu_off_by_default() abort
  call assert_equal('off', hpc#get_gpu_mode())
  call assert_equal('', hpc#get_gpu_flags())
endfunction

function! Test_status_line_reports_state() abort
  call profiles#set_compiler('gfortran')
  call profiles#set_profile('release')
  let l:status = profiles#status()
  call assert_match('gfortran', l:status)
  call assert_match('\crelease', l:status)
endfunction

function! Test_buffer_option_overrides_global() abort
  let g:fortran_compiler = 'gfortran'
  let b:fortran_compiler = 'ifx'
  try
    call assert_equal('ifx', makes#get_opt('fortran_compiler', 'none'))
  finally
    unlet b:fortran_compiler
  endtry
endfunction

function! Test_get_opt_falls_back_to_default() abort
  call assert_equal('fallback', makes#get_opt('fortran_no_such_option', 'fallback'))
endfunction

function! Test_completion_offers_known_profiles() abort
  let l:got = profiles#complete_profile('', '', 0)
  let l:list = type(l:got) == v:t_list ? l:got : split(l:got, "\n")
  call assert_notequal(-1, index(l:list, 'debug'))
  call assert_notequal(-1, index(l:list, 'release'))
endfunction
