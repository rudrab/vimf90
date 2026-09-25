"########################################################################
" File:          autoload/scratch.vim
" Author:        Rudra Banerjee (bnrj DOT rudra at gmail.com)
" License:       GPLv3
" Description:   Instant Ephemeral Scientific Fortran Scratchpad Environment
"########################################################################

let s:save_cpo = &cpo
set cpo&vim

let s:templates = {
      \ 'program': [
      \   'program scratch',
      \   '  use, intrinsic :: iso_fortran_env, only: dp => real64, int32, stdout => output_unit',
      \   '  implicit none',
      \   '',
      \   '  real(dp) :: x, y',
      \   '',
      \   '  print *, "=== Scientific Fortran Scratchpad ==="',
      \   '  x = 42.0_dp',
      \   '  y = sqrt(x)',
      \   '  write(stdout, "(A, F12.6)") " sqrt(x) = ", y',
      \   'end program scratch'
      \ ],
      \ 'matrix': [
      \   'program scratch_matrix',
      \   '  use, intrinsic :: iso_fortran_env, only: dp => real64, int32, stdout => output_unit',
      \   '  implicit none',
      \   '',
      \   '  integer, parameter :: n = 4',
      \   '  real(dp), dimension(n, n) :: A, B, C',
      \   '  integer :: i',
      \   '',
      \   '  call random_number(A)',
      \   '  call random_number(B)',
      \   '  C = matmul(A, B)',
      \   '',
      \   '  write(stdout, "(A)") "Matrix Product C = A x B:"',
      \   '  do i = 1, n',
      \   '    write(stdout, "(4(F9.4, 1X))") C(i, :)',
      \   '  end do',
      \   'end program scratch_matrix'
      \ ],
      \ 'openmp': [
      \   'program scratch_openmp',
      \   '  use, intrinsic :: iso_fortran_env, only: dp => real64, stdout => output_unit',
      \   '  use omp_lib',
      \   '  implicit none',
      \   '',
      \   '  integer :: tid, nthreads',
      \   '',
      \   '  !$omp parallel private(tid)',
      \   '  tid = omp_get_thread_num()',
      \   '  nthreads = omp_get_num_threads()',
      \   '  write(stdout, "(A, I0, A, I0)") "Hello from OpenMP thread ", tid, " of ", nthreads',
      \   '  !$omp end parallel',
      \   'end program scratch_openmp'
      \ ],
      \ 'module': [
      \   'module scratch_mod',
      \   '  use, intrinsic :: iso_fortran_env, only: dp => real64',
      \   '  implicit none',
      \   '  private',
      \   '  public :: compute_energy',
      \   '',
      \   'contains',
      \   '',
      \   '  pure function compute_energy(mass, velocity) result(energy)',
      \   '    real(dp), intent(in) :: mass, velocity',
      \   '    real(dp)             :: energy',
      \   '    energy = 0.5_dp * mass * (velocity ** 2)',
      \   '  end function compute_energy',
      \   '',
      \   'end module scratch_mod',
      \   '',
      \   'program test_scratch_mod',
      \   '  use scratch_mod',
      \   '  use, intrinsic :: iso_fortran_env, only: dp => real64, stdout => output_unit',
      \   '  implicit none',
      \   '',
      \   '  real(dp) :: m, v, e',
      \   '  m = 2.5_dp',
      \   '  v = 10.0_dp',
      \   '  e = compute_energy(m, v)',
      \   '  write(stdout, "(A, F10.4, A)") "Kinetic Energy: ", e, " J"',
      \   'end program test_scratch_mod'
      \ ],
      \ 'test': [
      \   'program scratch_test',
      \   '  use, intrinsic :: iso_fortran_env, only: dp => real64, stdout => output_unit, stderr => error_unit',
      \   '  implicit none',
      \   '',
      \   '  real(dp) :: expected, actual, tol',
      \   '  tol = 1.0e-12_dp',
      \   '  expected = 4.0_dp',
      \   '  actual = 2.0_dp * 2.0_dp',
      \   '',
      \   '  if (abs(actual - expected) < tol) then',
      \   '    write(stdout, "(A)") "[PASS] Calculation verified."',
      \   '  else',
      \   '    write(stderr, "(A, F12.6, A, F12.6)") "[FAIL] Expected ", expected, " but got ", actual',
      \   '    stop 1',
      \   '  end if',
      \   'end program scratch_test'
      \ ]
      \ }

let s:scratch_out_bufnr = -1

function! scratch#open(...) abort
  let l:tmpl_name = a:0 > 0 && !empty(a:1) ? tolower(trim(a:1)) : 'program'
  let l:split_cmd = get(g:, 'fortran_scratch_split', 'botright vsplit')

  " Open split window
  execute l:split_cmd
  enew
  setlocal buftype=nofile bufhidden=wipe noswapfile
  setlocal filetype=fortran
  silent! file `='[Fortran Scratchpad - ' . l:tmpl_name . ']'`

  let l:content = get(s:templates, l:tmpl_name, s:templates['program'])
  call setline(1, l:content)

  " Buffer-local commands & hints
  nnoremap <buffer> <silent> <Plug>(vimf90-scratch-run) :call scratch#run()<CR>
  command! -buffer -bar FortranScratchRun call scratch#run()

  echomsg 'vimf90: Scratchpad ready [' . l:tmpl_name . ']. Press <leader>sr or :FortranScratchRun to execute.'
  return bufnr('%')
endfunction

function! s:show_output(title, lines, is_error) abort
  let l:out_split = get(g:, 'fortran_scratch_out_split', 'botright 10split')
  let l:cur_win = win_getid()

  if s:scratch_out_bufnr <= 0 || !bufexists(s:scratch_out_bufnr)
    execute l:out_split
    let s:scratch_out_bufnr = bufnr('%')
    setlocal buftype=nofile bufhidden=wipe noswapfile
    silent! file [Fortran Scratch Output]
  else
    let l:win_list = win_findbuf(s:scratch_out_bufnr)
    if !empty(l:win_list)
      call win_gotoid(l:win_list[0])
    else
      execute l:out_split
      execute 'buffer ' . s:scratch_out_bufnr
    endif
  endif

  setlocal modifiable
  silent! %delete _
  let l:header = ['=== ' . a:title . ' (' . strftime('%H:%M:%S') . ') ===']
  call setline(1, l:header + a:lines)
  setlocal nomodifiable
  setlocal nonumber norelativenumber

  " Restore focus back to scratchpad
  call win_gotoid(l:cur_win)
endfunction

function! scratch#run() abort
  let l:lines = getline(1, '$')
  if empty(l:lines) || (len(l:lines) == 1 && empty(l:lines[0]))
    echohl WarningMsg | echo 'vimf90: Scratchpad is empty.' | echohl None
    return
  endif

  let l:tmp_src = tempname() . '.f90'
  let l:tmp_bin = tempname()

  " Write scratch buffer to temp file
  call writefile(l:lines, l:tmp_src)

  let l:compiler = profiles#get_effective_compiler()
  let l:flags = profiles#get_flags()

  " Build command
  let l:compile_cmd = l:compiler . ' ' . l:flags . ' ' . fnameescape(l:tmp_src) . ' -o ' . fnameescape(l:tmp_bin)

  echon 'Compiling & running scratchpad with ' . l:compiler . '...'

  let l:comp_out = system(l:compile_cmd)
  if v:shell_error != 0
    " Compilation error
    call delete(l:tmp_src)
    call delete(l:tmp_bin)
    echohl ErrorMsg | echo 'Scratchpad build failed!' | echohl None
    let l:err_lines = split(l:comp_out, "\n")
    call s:show_output('Scratchpad Compilation Error', l:err_lines, 1)
    " Also populate quickfix
    cclose
    call setqflist([], 'r', {'title': 'Scratchpad Build Error', 'lines': l:err_lines})
    botright cwindow
    return
  endif

  " Execute binary
  let l:run_out = system(fnameescape(l:tmp_bin))
  let l:run_exit = v:shell_error

  " Cleanup temp artifacts
  call delete(l:tmp_src)
  call delete(l:tmp_bin)
  " Also clean up any module (.mod) files generated in current directory
  let l:mod_files = glob('scratch_*.mod', 0, 1)
  for l:m in l:mod_files
    call delete(l:m)
  endfor

  redraw!
  let l:out_lines = split(l:run_out, "\n")
  if empty(l:out_lines)
    let l:out_lines = ['(Program exited with code ' . l:run_exit . ' and no output)']
  else
    call add(l:out_lines, '')
    call add(l:out_lines, '(Process completed with exit code ' . l:run_exit . ')')
  endif

  call s:show_output('Scratchpad Output', l:out_lines, l:run_exit != 0)
  echomsg 'vimf90: Scratchpad executed successfully.'
endfunction

function! scratch#complete_template(ArgLead, CmdLine, CursorPos) abort
  let l:list = keys(s:templates)
  return filter(l:list, 'v:val =~ "^" . a:ArgLead')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
