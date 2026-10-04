"########################################################################
" File:          autoload/state.vim
" Author:        Rudra Banerjee (bnrj DOT rudra at gmail.com)
" License:       GPLv3
" Description:   Unified buffer state object (b:vimf90) — centralizes all
"                per-buffer plugin state into a single dictionary with
"                accessor helpers and backward-compatible fallback.
"########################################################################

let s:save_cpo = &cpo
set cpo&vim

" Default values for state keys. These are consulted when neither the buffer
" dictionary, the legacy b:fortran_* variable, nor the g:fortran_* global
" provides a value.
let s:defaults = {
      \ 'compiler':     'gfortran',
      \ 'profile':      'debug',
      \ 'flags':        '',
      \ 'openmp':       0,
      \ 'mpi':          0,
      \ 'gpu':          'off',
      \ 'extra_flags':  '',
      \ 'project_root': '',
      \ 'exe_path':     '',
      \ 'cla':          '',
      \ 'make_args':    '',
      \ }

" Global variable names for fallback (g:fortran_*)
let s:legacy_global_map = {
      \ 'compiler':     'fortran_compiler',
      \ 'profile':      'fortran_profile',
      \ 'flags':        'fortran_flflags',
      \ 'openmp':       'fortran_openmp',
      \ 'mpi':          'fortran_mpi',
      \ 'gpu':          'fortran_gpu',
      \ 'extra_flags':  'fortran_extra_flags',
      \ 'project_root': 'fortran_project_root',
      \ }

" Legacy buffer variable names for fallback (b:*)
" Note: b:fortran_profile, b:fortran_openmp, b:fortran_mpi, b:fortran_gpu are
" keybinding storage variables in ftplugin/fortran_maps.vim, NOT state overrides.
let s:legacy_buf_map = {
      \ 'compiler':     'fortran_compiler',
      \ 'project_root': 'fortran_project_root',
      \ 'flags':        'fortran_flflags',
      \ 'cla':          'Clargs',
      \ 'make_args':    'MakeArgs',
      \ }

" Initialize b:vimf90 for the current buffer. Safe to call multiple times;
" merges without discarding existing state.
function! state#init() abort
  if !exists('b:vimf90')
    let b:vimf90 = {}
  endif

  " Seed from any existing legacy buffer variables if present
  for [l:key, l:legacy] in items(s:legacy_buf_map)
    if !has_key(b:vimf90, l:key) && exists('b:' . l:legacy)
      let b:vimf90[l:key] = get(b:, l:legacy)
    endif
  endfor
endfunction

" Get a state value. Resolution order:
"   1. b:vimf90[key]            — canonical per-buffer state
"   2. b: legacy buffer var     — buffer-level overrides (e.g. b:fortran_compiler)
"   3. g: global fallback       — global configuration (e.g. g:fortran_profile)
"   4. s:defaults[key]          — built-in default
function! state#get(key, ...) abort
  " 1. Canonical state dict
  if exists('b:vimf90') && has_key(b:vimf90, a:key)
    return b:vimf90[a:key]
  endif

  " 2. Legacy buffer variable (for keys that support buffer overrides)
  if has_key(s:legacy_buf_map, a:key)
    let l:bvar = s:legacy_buf_map[a:key]
    if exists('b:' . l:bvar)
      return get(b:, l:bvar)
    endif
  endif

  " 3. Global variable, but only for keys that actually have one. A generic
  " g:fortran_<key> fallback would collide with the mapping variables: cla is
  " command line arguments here, while g:fortran_cla is the key that opens the
  " prompt for them.
  if has_key(s:legacy_global_map, a:key)
    let l:gvar = s:legacy_global_map[a:key]
    if exists('g:' . l:gvar)
      return get(g:, l:gvar)
    endif
  endif

  " 4. Default
  if a:0 > 0
    return a:1
  endif
  return get(s:defaults, a:key, '')
endfunction

" Set a state value in b:vimf90. Initializes the dict if absent.
function! state#set(key, value) abort
  if !exists('b:vimf90')
    let b:vimf90 = {}
  endif
  let b:vimf90[a:key] = a:value
endfunction

" Check whether a state key is truthy (non-zero number, non-empty string).
function! state#is(key) abort
  let l:val = state#get(a:key)
  if type(l:val) == v:t_number
    return l:val != 0
  endif
  if type(l:val) == v:t_string
    return l:val !=# '' && l:val !=# 'off' && l:val !=# '0'
  endif
  return !empty(l:val)
endfunction

" Return a snapshot of the full state, merging defaults, globals, legacy
" buffer vars, and the b:vimf90 dict.
function! state#snapshot() abort
  let l:snap = copy(s:defaults)

  " Layer globals
  for [l:key, l:gvar] in items(s:legacy_global_map)
    if exists('g:' . l:gvar)
      let l:snap[l:key] = get(g:, l:gvar)
    endif
  endfor

  " Layer legacy buffer vars
  for [l:key, l:bvar] in items(s:legacy_buf_map)
    if exists('b:' . l:bvar)
      let l:snap[l:key] = get(b:, l:bvar)
    endif
  endfor

  " Layer b:vimf90 (highest priority)
  if exists('b:vimf90')
    call extend(l:snap, b:vimf90)
  endif

  return l:snap
endfunction

" Remove b:vimf90 entirely. Called from b:undo_ftplugin.
function! state#cleanup() abort
  unlet! b:vimf90
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
