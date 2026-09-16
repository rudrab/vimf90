"########################################################################
" File:          ftplugin/fortran_maps.vim
" Author:        Rudra Banerjee (bnrj DOT rudra at gmail.com)
" Version:       0.6
" License:       GPLv3
" Description:   Buffer-local key mappings, text objects, and motions
"########################################################################

let s:save_cpo = &cpo
set cpo&vim

if exists('g:fortran_no_mappings') && g:fortran_no_mappings
  let &cpo = s:save_cpo
  unlet s:save_cpo
  finish
endif

let s:leader = get(g:, 'fortran_leader', get(g:, 'mapleader', '\'))

let b:fortran_compile       = get(g:, 'fortran_compile',       s:leader . 'cc')
let b:fortran_exe           = get(g:, 'fortran_exe',           s:leader . 'ce')
let b:fortran_run           = get(g:, 'fortran_run',           s:leader . 'cr')
let b:fortran_cla           = get(g:, 'fortran_cla',           s:leader . 'cl')
let b:fortran_dbg           = get(g:, 'fortran_dbg',           s:leader . 'cd')
let b:fortran_make          = get(g:, 'fortran_make',          s:leader . 'mk')
let b:fortran_makeProp      = get(g:, 'fortran_makeProp',      s:leader . 'mp')
let b:fortran_fpm_build     = get(g:, 'fortran_fpm_build',      s:leader . 'fb')
let b:fortran_fpm_run       = get(g:, 'fortran_fpm_run',        s:leader . 'fr')
let b:fortran_fpm_test      = get(g:, 'fortran_fpm_test',       s:leader . 'ft')
let b:fortran_fpm_test_cur  = get(g:, 'fortran_fpm_test_cur',   s:leader . 'tc')
let b:fortran_tags          = get(g:, 'fortran_tags',           s:leader . 'tg')
let b:fortran_find_mod      = get(g:, 'fortran_find_mod',       s:leader . 'fm')
let b:fortran_doc           = get(g:, 'fortran_doc_map',        s:leader . 'dc')
let b:fortran_ford_build    = get(g:, 'fortran_ford_build_map', s:leader . 'db')
let b:fortran_ford_preview  = get(g:, 'fortran_ford_prev_map',  s:leader . 'dp')
let b:fortran_profile       = get(g:, 'fortran_prof_map',       s:leader . 'pp')
let b:fortran_openmp        = get(g:, 'fortran_omp_map',        s:leader . 'po')
let b:fortran_mpi           = get(g:, 'fortran_mpi_map',        s:leader . 'pm')

let s:undo_maps = []

function! s:map_buf(mode, key, plug) abort
  if !empty(a:key)
    execute a:mode . 'map <buffer> <silent>' a:key a:plug
    call add(s:undo_maps, 'silent! ' . a:mode . 'unmap <buffer> ' . a:key)
  endif
endfunction

" Core operation mappings
call s:map_buf('n', b:fortran_compile,       '<Plug>(vimf90-compile)')
call s:map_buf('n', b:fortran_exe,           '<Plug>(vimf90-exe)')
call s:map_buf('n', b:fortran_run,           '<Plug>(vimf90-run)')
call s:map_buf('n', b:fortran_cla,           '<Plug>(vimf90-cla)')
call s:map_buf('n', b:fortran_dbg,           '<Plug>(vimf90-dbg)')
call s:map_buf('n', b:fortran_make,          '<Plug>(vimf90-make)')
call s:map_buf('n', b:fortran_makeProp,      '<Plug>(vimf90-makeprop)')
call s:map_buf('n', b:fortran_fpm_build,     '<Plug>(vimf90-fpm-build)')
call s:map_buf('n', b:fortran_fpm_run,       '<Plug>(vimf90-fpm-run)')
call s:map_buf('n', b:fortran_fpm_test,      '<Plug>(vimf90-fpm-test)')
call s:map_buf('n', b:fortran_fpm_test_cur,  '<Plug>(vimf90-fpm-test-current)')
call s:map_buf('n', b:fortran_tags,          '<Plug>(vimf90-tags)')
call s:map_buf('n', b:fortran_find_mod,      '<Plug>(vimf90-find-module)')
call s:map_buf('n', b:fortran_doc,           '<Plug>(vimf90-doc)')
call s:map_buf('n', b:fortran_ford_build,    '<Plug>(vimf90-ford-build)')
call s:map_buf('n', b:fortran_ford_preview,  '<Plug>(vimf90-ford-preview)')
call s:map_buf('n', b:fortran_profile,       '<Plug>(vimf90-profile)')
call s:map_buf('n', b:fortran_openmp,        '<Plug>(vimf90-openmp)')
call s:map_buf('n', b:fortran_mpi,           '<Plug>(vimf90-mpi)')

" Text Objects (x = Visual, o = Operator-pending)
if get(g:, 'fortran_enable_textobjects', 1)
  for s:m in ['x', 'o']
    call s:map_buf(s:m, 'af', '<Plug>(vimf90-textobj-func-a)')
    call s:map_buf(s:m, 'if', '<Plug>(vimf90-textobj-func-i)')
    call s:map_buf(s:m, 'am', '<Plug>(vimf90-textobj-mod-a)')
    call s:map_buf(s:m, 'im', '<Plug>(vimf90-textobj-mod-i)')
    call s:map_buf(s:m, 'at', '<Plug>(vimf90-textobj-type-a)')
    call s:map_buf(s:m, 'it', '<Plug>(vimf90-textobj-type-i)')
    call s:map_buf(s:m, 'ad', '<Plug>(vimf90-textobj-do-a)')
    call s:map_buf(s:m, 'id', '<Plug>(vimf90-textobj-do-i)')
    call s:map_buf(s:m, 'ab', '<Plug>(vimf90-textobj-block-a)')
    call s:map_buf(s:m, 'ib', '<Plug>(vimf90-textobj-block-i)')
  endfor
endif

" Structural Motions (n = Normal, x = Visual, o = Operator-pending)
if get(g:, 'fortran_enable_motions', 1)
  for s:m in ['n', 'x', 'o']
    call s:map_buf(s:m, ']m', '<Plug>(vimf90-motion-next-start)')
    call s:map_buf(s:m, '[m', '<Plug>(vimf90-motion-prev-start)')
    call s:map_buf(s:m, ']M', '<Plug>(vimf90-motion-next-end)')
    call s:map_buf(s:m, '[M', '<Plug>(vimf90-motion-prev-end)')
  endfor
endif

" Timestamp update on save {{{1
function! s:update_timestamp() abort
  if &readonly || !&modifiable
    return
  endif
  let l:view = winsaveview()
  let l:search = @/
  silent! keeppatterns %s/\v^(!\s*Last Modified:\s*).*/\=submatch(1) . strftime("%c")/e
  let @/ = l:search
  call winrestview(l:view)
endfunction

if get(g:, 'fortran_update_timestamp', 1)
  augroup vimf90_timestamp
    autocmd! * <buffer>
    autocmd BufWritePre <buffer> call s:update_timestamp()
  augroup END
endif
"}}}1

" Undo ftplugin
let s:undo_vars = 'unlet! b:fortran_compile b:fortran_exe b:fortran_run b:fortran_cla b:fortran_dbg b:fortran_make b:fortran_makeProp b:fortran_fpm_build b:fortran_fpm_run b:fortran_fpm_test b:fortran_fpm_test_cur b:fortran_tags b:fortran_find_mod b:fortran_doc b:fortran_ford_build b:fortran_ford_preview b:fortran_profile b:fortran_openmp b:fortran_mpi'
let s:undo = s:undo_vars . ' | silent! augroup vimf90_timestamp | silent! autocmd! * <buffer> | silent! augroup END'
if !empty(s:undo_maps)
  let s:undo .= ' | ' . join(s:undo_maps, ' | ')
endif

let b:undo_ftplugin = (exists('b:undo_ftplugin') ? b:undo_ftplugin . ' | ' : '') . s:undo

let &cpo = s:save_cpo
unlet s:save_cpo
