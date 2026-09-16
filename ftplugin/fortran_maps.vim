"########################################################################
" File:          ftplugin/fortran_maps.vim
" Author:        Rudra Banerjee (bnrj DOT rudra at gmail.com)
" Version:       0.3
" License:       GPLv3
" Description:   Buffer-local key mappings for Fortran operations
"########################################################################

if exists('g:fortran_no_mappings') && g:fortran_no_mappings
  finish
endif

let s:leader = get(g:, 'fortran_leader', get(g:, 'mapleader', '\'))

let b:fortran_compile  = get(g:, 'fortran_compile',  s:leader . 'cc')
let b:fortran_exe      = get(g:, 'fortran_exe',      s:leader . 'ce')
let b:fortran_run      = get(g:, 'fortran_run',      s:leader . 'cr')
let b:fortran_cla      = get(g:, 'fortran_cla',      s:leader . 'cl')
let b:fortran_dbg      = get(g:, 'fortran_dbg',      s:leader . 'cd')
let b:fortran_make     = get(g:, 'fortran_make',     s:leader . 'mk')
let b:fortran_makeProp = get(g:, 'fortran_makeProp', s:leader . 'mp')
let b:fortran_genProj  = get(g:, 'fortran_genProj',  s:leader . 'gp')

let s:undo_maps = []

if !empty(b:fortran_compile)
  execute 'nmap <buffer> <silent>' b:fortran_compile '<Plug>(vimf90-compile)'
  call add(s:undo_maps, 'silent! nunmap <buffer> ' . b:fortran_compile)
endif
if !empty(b:fortran_exe)
  execute 'nmap <buffer> <silent>' b:fortran_exe '<Plug>(vimf90-exe)'
  call add(s:undo_maps, 'silent! nunmap <buffer> ' . b:fortran_exe)
endif
if !empty(b:fortran_run)
  execute 'nmap <buffer> <silent>' b:fortran_run '<Plug>(vimf90-run)'
  call add(s:undo_maps, 'silent! nunmap <buffer> ' . b:fortran_run)
endif
if !empty(b:fortran_cla)
  execute 'nmap <buffer> <silent>' b:fortran_cla '<Plug>(vimf90-cla)'
  call add(s:undo_maps, 'silent! nunmap <buffer> ' . b:fortran_cla)
endif
if !empty(b:fortran_dbg)
  execute 'nmap <buffer> <silent>' b:fortran_dbg '<Plug>(vimf90-dbg)'
  call add(s:undo_maps, 'silent! nunmap <buffer> ' . b:fortran_dbg)
endif
if !empty(b:fortran_make)
  execute 'nmap <buffer> <silent>' b:fortran_make '<Plug>(vimf90-make)'
  call add(s:undo_maps, 'silent! nunmap <buffer> ' . b:fortran_make)
endif
if !empty(b:fortran_makeProp)
  execute 'nmap <buffer> <silent>' b:fortran_makeProp '<Plug>(vimf90-makeprop)'
  call add(s:undo_maps, 'silent! nunmap <buffer> ' . b:fortran_makeProp)
endif
if !empty(b:fortran_genProj)
  execute 'nmap <buffer> <silent>' b:fortran_genProj '<Plug>(vimf90-makeproj)'
  call add(s:undo_maps, 'silent! nunmap <buffer> ' . b:fortran_genProj)
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
let s:undo = 'unlet! b:fortran_compile b:fortran_exe b:fortran_run b:fortran_cla b:fortran_dbg b:fortran_make b:fortran_makeProp b:fortran_genProj'
let s:undo .= ' | silent! augroup vimf90_timestamp | silent! autocmd! * <buffer> | silent! augroup END'
if !empty(s:undo_maps)
  let s:undo .= ' | ' . join(s:undo_maps, ' | ')
endif

let b:undo_ftplugin = (exists('b:undo_ftplugin') ? b:undo_ftplugin . ' | ' : '') . s:undo
