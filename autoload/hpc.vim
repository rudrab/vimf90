"########################################################################
" File:          autoload/hpc.vim
" Author:        Rudra Banerjee (bnrj DOT rudra at gmail.com)
" License:       GPLv3
" Description:   Supercomputing & Modern Parallel Standards (MPI Cluster Launcher,
"                Coarray Fortran CAF, OpenACC & OpenMP GPU Offloading)
"########################################################################

let s:save_cpo = &cpo
set cpo&vim

" Coarray Fortran (CAF) Presets {{{1
let s:caf_presets = {
      \ 'gfortran': {
      \   'single':      '-fcoarray=single',
      \   'lib':         '-fcoarray=lib -lcaf_mpi',
      \   'compiler':    'caf',
      \   'runner':      'cafrun'
      \ },
      \ 'ifx': {
      \   'single':      '-coarray=shared',
      \   'lib':         '-coarray=distributed',
      \   'shared':      '-coarray=shared',
      \   'distributed': '-coarray=distributed',
      \   'compiler':    'ifx',
      \   'runner':      'mpirun'
      \ },
      \ 'ifort': {
      \   'single':      '-coarray=shared',
      \   'lib':         '-coarray=distributed',
      \   'shared':      '-coarray=shared',
      \   'distributed': '-coarray=distributed',
      \   'compiler':    'ifort',
      \   'runner':      'mpirun'
      \ },
      \ 'nvfortran': {
      \   'single':      '-Mcarray',
      \   'lib':         '-Mcarray',
      \   'compiler':    'nvfortran',
      \   'runner':      'mpirun'
      \ }
      \ }

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

function! hpc#is_caf() abort
  return get(g:, 'fortran_caf', 0)
endfunction

function! hpc#get_caf_mode() abort
  return get(g:, 'fortran_caf_mode', 'single')
endfunction

function! hpc#get_gpu_mode() abort
  return get(g:, 'fortran_gpu', 'off')
endfunction

function! hpc#get_caf_flags() abort
  if !hpc#is_caf()
    return ''
  endif
  let l:comp = profiles#get_compiler()
  let l:mode = hpc#get_caf_mode()
  let l:preset = get(s:caf_presets, l:comp, get(s:caf_presets, 'gfortran'))
  return get(l:preset, l:mode, get(l:preset, 'single', '-fcoarray=single'))
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

function! hpc#toggle_caf(...) abort
  if a:0 > 0 && !empty(a:1)
    let l:arg = tolower(trim(a:1))
    if l:arg ==# 'off' || l:arg ==# '0' || l:arg ==# 'false'
      let g:fortran_caf = 0
    else
      let g:fortran_caf = 1
      if l:arg !=# 'on' && l:arg !=# '1'
        let g:fortran_caf_mode = l:arg
      endif
    endif
  else
    let g:fortran_caf = !get(g:, 'fortran_caf', 0)
  endif

  let l:status = g:fortran_caf ? ('ENABLED [' . hpc#get_caf_mode() . ' mode, Flags: ' . hpc#get_caf_flags() . ']') : 'DISABLED'
  echo 'vimf90: Coarray Fortran (CAF) ' . l:status
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

function! hpc#caf_run(...) abort
  let l:images = a:0 > 0 && !empty(a:1) ? a:1 : get(g:, 'fortran_caf_images', 4)
  let l:comp = profiles#get_compiler()
  let l:preset = get(s:caf_presets, l:comp, get(s:caf_presets, 'gfortran'))
  let l:runner = get(l:preset, 'runner', 'cafrun')
  let l:extra_args = a:0 > 1 ? (' ' . a:2) : ''

  let l:exeext = makes#get_opt('fortran_exeExt', '')
  let l:exe = expand('%:p:r') . l:exeext
  if !filereadable(l:exe)
    let l:built = makes#Fexe(0)
    if !l:built
      return
    endif
  endif

  let l:cmd = l:runner . ' -n ' . l:images . ' ' . fnameescape(l:exe) . l:extra_args
  echo 'Running Coarray job (' . l:images . ' images): ' . l:cmd . ' ...'

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

function! hpc#complete_caf(ArgLead, CmdLine, CursorPos) abort
  let l:list = ['on', 'off', 'single', 'lib', 'shared', 'distributed']
  return filter(l:list, 'v:val =~ "^" . a:ArgLead')
endfunction

function! hpc#complete_gpu(ArgLead, CmdLine, CursorPos) abort
  let l:list = ['openmp', 'openacc', 'off']
  return filter(l:list, 'v:val =~ "^" . a:ArgLead')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
