"########################################################################
" File:          autoload/hpc.vim
" Author:        Rudra Banerjee (bnrj DOT rudra at gmail.com)
" License:       GPLv3
" Description:   High Performance Computing & Accelerators (MPI Cluster Launcher,
"                OpenACC & OpenMP GPU Offloading)
"########################################################################

let s:save_cpo = &cpo
set cpo&vim

" GPU Offloading Presets (OpenACC / OpenMP Target) {{{1
let s:gpu_presets = {
      \ 'nvfortran': {
      \   'openacc': '-acc -gpu=ccall -Minfo=accel',
      \   'openmp':  '-mp=gpu -gpu=ccall -Minfo=mp'
      \ },
      \ 'gfortran': {
      \   'openacc': '-fopenacc',
      \   'openmp':  '-fopenmp -foffload=nvptx-none'
      \ },
      \ 'ifx': {
      \   'openacc': '',
      \   'openmp':  '-qopenmp -fopenmp-targets=spir64'
      \ },
      \ 'flang': {
      \   'openacc': '',
      \   'openmp':  '-fopenmp --offload-arch=native'
      \ }
      \ }

function! hpc#get_gpu_mode() abort
  return get(g:, 'fortran_gpu', 'off')
endfunction

function! hpc#get_gpu_flags() abort
  let l:gpu = hpc#get_gpu_mode()
  if l:gpu ==# 'off' || empty(l:gpu)
    return ''
  endif
  let l:comp = profiles#get_compiler()
  let l:preset = get(s:gpu_presets, l:comp, {})
  return get(l:preset, l:gpu, '')
endfunction

function! hpc#toggle_gpu(...) abort
  if a:0 > 0 && !empty(a:1)
    let l:arg = tolower(trim(a:1))
    if l:arg ==# 'off' || l:arg ==# '0' || l:arg ==# 'false'
      let g:fortran_gpu = 'off'
    elseif l:arg ==# 'openacc' || l:arg ==# 'acc'
      let g:fortran_gpu = 'openacc'
    elseif l:arg ==# 'openmp' || l:arg ==# 'target' || l:arg ==# 'omp'
      let g:fortran_gpu = 'openmp'
    else
      let g:fortran_gpu = l:arg
    endif
  else
    let l:cur = hpc#get_gpu_mode()
    let g:fortran_gpu = (l:cur ==# 'off') ? 'openmp' : 'off'
  endif

  let l:status = (g:fortran_gpu !=# 'off') ? ('ENABLED [' . g:fortran_gpu . ', Flags: ' . hpc#get_gpu_flags() . ']') : 'DISABLED'
  echo 'vimf90: GPU Offloading ' . l:status
endfunction

function! hpc#mpi_run(...) abort
  let l:ranks = a:0 > 0 && !empty(a:1) ? a:1 : get(g:, 'fortran_mpi_ranks', 4)
  let l:runner = get(g:, 'fortran_mpi_runner', 'mpirun')
  let l:extra_args = a:0 > 1 ? (' ' . a:2) : ''

  let l:exeext = makes#get_opt('fortran_exeExt', '')
  let l:exe = expand('%:p:r') . l:exeext
  if !filereadable(l:exe)
    " Compile first
    let l:built = makes#Fexe(0)
    if !l:built
      return
    endif
  endif

  let l:cmd = l:runner . ' -n ' . l:ranks . ' ' . fnameescape(l:exe) . l:extra_args
  echo 'Running MPI cluster job: ' . l:cmd . ' ...'

  if makes#get_opt('fortran_run_terminal', 1) && (has('nvim') || exists(':terminal') == 2)
    if has('nvim')
      execute 'botright split | terminal ' . l:cmd
    else
      execute 'botright terminal ' . l:cmd
    endif
  else
    execute '!' . l:cmd
  endif
endfunction

function! hpc#complete_gpu(ArgLead, CmdLine, CursorPos) abort
  let l:list = ['openmp', 'openacc', 'off']
  return filter(l:list, 'v:val =~ "^" . a:ArgLead')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
