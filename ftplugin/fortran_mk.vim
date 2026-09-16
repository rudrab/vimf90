"########################################################################
" Filename:      ftplugin/fortran_mk.vim
" Copyright:     Copyright (C) 2019-2026 Rudra Banerjee
" License:       GPLv3
" Description:   Fortran build/run commands and plug mappings
"########################################################################

" Plug mappings
nnoremap <buffer> <silent> <Plug>(vimf90-compile)   :call makes#Fcompile()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-exe)       :call makes#Fexe()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-run)       :call makes#Frun()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-cla)       :call makes#Cla()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-dbg)       :call makes#Fdbg()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-make)      :call makes#MakeRun()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-makeprop)  :call makes#MakeCla()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-makeproj)  :call makes#MakeProj()<CR>

" User commands
command! -buffer -bar FortranCompile  call makes#Fcompile()
command! -buffer -bar FortranExe      call makes#Fexe()
command! -buffer -bar FortranRun      call makes#Frun()
command! -buffer -bar FortranArgs     call makes#Cla()
command! -buffer -bar FortranDebug    call makes#Fdbg()
command! -buffer -bar FortranMake     call makes#MakeRun()
command! -buffer -bar FortranMakeArgs call makes#MakeCla()
command! -buffer -bar FortranMakeProj call makes#MakeProj()

" Legacy helper function wrappers for backwards compatibility
function! Compile() abort
  return makes#Fcompile()
endfunction

function! Gexe() abort
  return makes#Fexe()
endfunction

function! Run() abort
  return makes#Frun()
endfunction

function! CLArgs() abort
  return makes#Cla()
endfunction

function! Debug() abort
  return makes#Fdbg()
endfunction

function! Make() abort
  return makes#MakeRun()
endfunction

function! MakeProperties() abort
  return makes#MakeCla()
endfunction

function! MakeProject() abort
  return makes#MakeProj()
endfunction

" Undo ftplugin
let s:undo = 'delcommand FortranCompile | delcommand FortranExe | delcommand FortranRun | delcommand FortranArgs | delcommand FortranDebug | delcommand FortranMake | delcommand FortranMakeArgs | delcommand FortranMakeProj'
let s:undo .= ' | silent! nunmap <buffer> <Plug>(vimf90-compile) | silent! nunmap <buffer> <Plug>(vimf90-exe) | silent! nunmap <buffer> <Plug>(vimf90-run) | silent! nunmap <buffer> <Plug>(vimf90-cla) | silent! nunmap <buffer> <Plug>(vimf90-dbg) | silent! nunmap <buffer> <Plug>(vimf90-make) | silent! nunmap <buffer> <Plug>(vimf90-makeprop) | silent! nunmap <buffer> <Plug>(vimf90-makeproj)'
let b:undo_ftplugin = (exists('b:undo_ftplugin') ? b:undo_ftplugin . ' | ' : '') . s:undo
