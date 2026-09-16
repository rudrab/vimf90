"########################################################################
" File:          ftplugin/fortran_maps.vim
" Author:        Rudra Banerjee (bnrj DOT rudra at gmail.com)
" Version:       0.4
" License:       GPLv3
" Description:   Buffer-local key mappings for Fortran operations
"########################################################################

if exists('g:fortran_no_mappings') && g:fortran_no_mappings
  finish
endif

let s:leader = get(g:, 'fortran_leader', get(g:, 'mapleader', '\'))

let b:fortran_compile   = get(g:, 'fortran_compile',   s:leader . 'cc')
let b:fortran_exe       = get(g:, 'fortran_exe',       s:leader . 'ce')
let b:fortran_run       = get(g:, 'fortran_run',       s:leader . 'cr')
let b:fortran_cla       = get(g:, 'fortran_cla',       s:leader . 'cl')
let b:fortran_dbg       = get(g:, 'fortran_dbg',       s:leader . 'cd')
let b:fortran_make      = get(g:, 'fortran_make',      s:leader . 'mk')
let b:fortran_makeProp  = get(g:, 'fortran_makeProp',  s:leader . 'mp')
let b:fortran_genProj   = get(g:, 'fortran_genProj',   s:leader . 'gp')
let b:fortran_fpm_build = get(g:, 'fortran_fpm_build',  s:leader . 'fb')
let b:fortran_fpm_run   = get(g:, 'fortran_fpm_run',    s:leader . 'fr')
let b:fortran_fpm_test  = get(g:, 'fortran_fpm_test',   s:leader . 'ft')
let b:fortran_tags      = get(g:, 'fortran_tags',       s:leader . 'tg')
let b:fortran_find_mod  = get(g:, 'fortran_find_mod',   s:leader . 'fm')

let s:undo_maps = []

function! s:map_buf(key, plug) abort
  if !empty(a:key)
    execute 'nmap <buffer> <silent>' a:key a:plug
    call add(s:undo_maps, 'silent! nunmap <buffer> ' . a:key)
  endif
endfunction

call s:map_buf(b:fortran_compile,   '<Plug>(vimf90-compile)')
call s:map_buf(b:fortran_exe,       '<Plug>(vimf90-exe)')
call s:map_buf(b:fortran_run,       '<Plug>(vimf90-run)')
call s:map_buf(b:fortran_cla,       '<Plug>(vimf90-cla)')
call s:map_buf(b:fortran_dbg,       '<Plug>(vimf90-dbg)')
call s:map_buf(b:fortran_make,      '<Plug>(vimf90-make)')
call s:map_buf(b:fortran_makeProp,  '<Plug>(vimf90-makeprop)')
call s:map_buf(b:fortran_genProj,   '<Plug>(vimf90-makeproj)')
call s:map_buf(b:fortran_fpm_build, '<Plug>(vimf90-fpm-build)')
call s:map_buf(b:fortran_fpm_run,   '<Plug>(vimf90-fpm-run)')
call s:map_buf(b:fortran_fpm_test,  '<Plug>(vimf90-fpm-test)')
call s:map_buf(b:fortran_tags,      '<Plug>(vimf90-tags)')
call s:map_buf(b:fortran_find_mod,  '<Plug>(vimf90-find-module)')

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
let s:undo = 'unlet! b:fortran_compile b:fortran_exe b:fortran_run b:fortran_cla b:fortran_dbg b:fortran_make b:fortran_makeProp b:fortran_genProj b:fortran_fpm_build b:fortran_fpm_run b:fortran_fpm_test b:fortran_tags b:fortran_find_mod'
let s:undo .= ' | silent! augroup vimf90_timestamp | silent! autocmd! * <buffer> | silent! augroup END'
if !empty(s:undo_maps)
  let s:undo .= ' | ' . join(s:undo_maps, ' | ')
endif

let b:undo_ftplugin = (exists('b:undo_ftplugin') ? b:undo_ftplugin . ' | ' : '') . s:undo
