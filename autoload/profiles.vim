"########################################################################
" File:          autoload/profiles.vim
" Author:        Rudra Banerjee (bnrj DOT rudra at gmail.com)
" License:       GPLv3
" Description:   Build Profiles (Debug, Release, Fast, Sanitize), OpenMP,
"                and MPI Compiler Presets for modern Fortran
"########################################################################

let s:save_cpo = &cpo
set cpo&vim

" Presets per compiler
let s:presets = {
      \ 'gfortran': {
      \   'debug':    '-g -O0 -Wall -Wextra -Wno-unused-parameter -fcheck=all -fbacktrace -fcoarray=single',
      \   'release':  '-O3 -march=native -funroll-loops -fcoarray=single',
      \   'fast':     '-O3 -ffast-math -march=native -fcoarray=single',
      \   'sanitize': '-g -O1 -fsanitize=address -fsanitize=undefined -fbacktrace -fcoarray=single',
      \   'openmp':   '-fopenmp',
      \   'mpi_bin':  'mpifort'
      \ },
      \ 'ifx': {
      \   'debug':    '-g -O0 -warn all -check all -traceback',
      \   'release':  '-O3 -xHost',
      \   'fast':     '-fast',
      \   'sanitize': '-g -O1 -traceback',
      \   'openmp':   '-qopenmp',
      \   'mpi_bin':  'mpiifx'
      \ },
      \ 'ifort': {
      \   'debug':    '-g -O0 -warn all -check all -traceback',
      \   'release':  '-O3 -xHost',
      \   'fast':     '-fast',
      \   'sanitize': '-g -O1 -traceback',
      \   'openmp':   '-qopenmp',
      \   'mpi_bin':  'mpiifort'
      \ },
      \ 'nvfortran': {
      \   'debug':    '-g -O0 -Minform=warn -Mbounds -Mchkptr -traceback',
      \   'release':  '-O3 -fast',
      \   'fast':     '-fast -Mvect',
      \   'sanitize': '-g -O1 -Mbounds',
      \   'openmp':   '-mp',
      \   'mpi_bin':  'mpif90'
      \ },
      \ 'flang': {
      \   'debug':    '-g -O0 -Wall',
      \   'release':  '-O3',
      \   'fast':     '-O3 -ffast-math',
      \   'sanitize': '-g -O1 -fsanitize=address,undefined',
      \   'openmp':   '-fopenmp',
      \   'mpi_bin':  'mpifort'
      \ }
      \ }

function! profiles#get_compiler() abort
  return get(g:, 'fortran_compiler', 'gfortran')
endfunction

function! profiles#get_profile() abort
  return get(g:, 'fortran_profile', 'debug')
endfunction

function! profiles#is_mpi() abort
  return get(g:, 'fortran_mpi', 0)
endfunction

function! profiles#is_openmp() abort
  return get(g:, 'fortran_openmp', 0)
endfunction

function! profiles#get_effective_compiler() abort
  let l:comp = profiles#get_compiler()
  if profiles#is_mpi()
    let l:preset = get(s:presets, l:comp, {})
    return get(l:preset, 'mpi_bin', 'mpifort')
  endif
  return l:comp
endfunction

function! profiles#get_flags() abort
  if exists('g:fortran_flflags_custom') && !empty(g:fortran_flflags_custom)
    return g:fortran_flflags_custom
  endif

  let l:comp = profiles#get_compiler()
  let l:prof = profiles#get_profile()
  let l:preset = get(s:presets, l:comp, get(s:presets, 'gfortran'))

  let l:flags = get(l:preset, l:prof, get(l:preset, 'debug', '-Wall -O0'))

  if profiles#is_openmp()
    let l:omp_flag = get(l:preset, 'openmp', '-fopenmp')
    let l:flags .= ' ' . l:omp_flag
  endif

  " GPU Offloading flags (OpenACC / OpenMP Target)
  if exists('*hpc#get_gpu_flags')
    let l:gpu_flag = hpc#get_gpu_flags()
    if !empty(l:gpu_flag)
      let l:flags .= ' ' . l:gpu_flag
    endif
  endif

  let l:extra = get(g:, 'fortran_extra_flags', '')
  if !empty(l:extra)
    let l:flags .= ' ' . l:extra
  endif

  return trim(l:flags)
endfunction

function! profiles#set_profile(name) abort
  let l:name = tolower(trim(a:name))
  if empty(l:name)
    echo 'vimf90 profile: ' . profiles#get_profile() . ' (Flags: ' . profiles#get_flags() . ')'
    return
  endif

  let l:valid = ['debug', 'release', 'fast', 'sanitize']
  if index(l:valid, l:name) == -1
    echoerr 'vimf90: Unknown profile "' . l:name . '". Valid options: ' . join(l:valid, ', ')
    return
  endif

  let g:fortran_profile = l:name
  echo 'vimf90: Set build profile to [' . l:name . ']. Flags: ' . profiles#get_flags()
endfunction

function! profiles#set_compiler(name) abort
  let l:name = tolower(trim(a:name))
  if empty(l:name)
    echo 'vimf90 compiler: ' . profiles#get_effective_compiler()
    return
  endif

  let g:fortran_compiler = l:name
  echo 'vimf90: Active compiler set to ' . l:name . ' (' . profiles#get_effective_compiler() . ')'
endfunction

function! profiles#toggle_mpi(...) abort
  if a:0 > 0 && !empty(a:1)
    let l:arg = tolower(trim(a:1))
    let g:fortran_mpi = (l:arg ==# 'on' || l:arg ==# '1' || l:arg ==# 'true') ? 1 : 0
  else
    let g:fortran_mpi = !get(g:, 'fortran_mpi', 0)
  endif

  echo 'vimf90: MPI mode ' . (g:fortran_mpi ? 'ENABLED (' . profiles#get_effective_compiler() . ')' : 'DISABLED (' . profiles#get_compiler() . ')')
endfunction

function! profiles#toggle_openmp(...) abort
  if a:0 > 0 && !empty(a:1)
    let l:arg = tolower(trim(a:1))
    let g:fortran_openmp = (l:arg ==# 'on' || l:arg ==# '1' || l:arg ==# 'true') ? 1 : 0
  else
    let g:fortran_openmp = !get(g:, 'fortran_openmp', 0)
  endif

  echo 'vimf90: OpenMP ' . (g:fortran_openmp ? 'ENABLED' : 'DISABLED') . '. Flags: ' . profiles#get_flags()
endfunction

function! profiles#status() abort
  let l:comp = profiles#get_effective_compiler()
  let l:prof = profiles#get_profile()
  let l:parts = [l:comp, toupper(l:prof[0]) . l:prof[1:]]

  if profiles#is_openmp()
    call add(l:parts, 'OMP')
  endif
  if profiles#is_mpi()
    call add(l:parts, 'MPI')
  endif
  if exists('*hpc#get_gpu_mode') && hpc#get_gpu_mode() !=# 'off'
    call add(l:parts, toupper(hpc#get_gpu_mode()))
  endif

  return '[' . join(l:parts, ':') . ']'
endfunction

" Completion helpers
function! profiles#complete_profile(ArgLead, CmdLine, CursorPos) abort
  let l:list = ['debug', 'release', 'fast', 'sanitize']
  return filter(l:list, 'v:val =~ "^" . a:ArgLead')
endfunction

function! profiles#complete_compiler(ArgLead, CmdLine, CursorPos) abort
  let l:list = ['gfortran', 'ifx', 'ifort', 'nvfortran', 'flang']
  return filter(l:list, 'v:val =~ "^" . a:ArgLead')
endfunction

function! profiles#complete_toggle(ArgLead, CmdLine, CursorPos) abort
  let l:list = ['on', 'off', 'toggle']
  return filter(l:list, 'v:val =~ "^" . a:ArgLead')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
