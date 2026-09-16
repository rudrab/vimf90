"########################################################################
" Filename:      ftplugin/fortran_mk.vim
" Copyright:     Copyright (C) 2019-2026 Rudra Banerjee
" License:       GPLv3
" Description:   Fortran build/run commands and plug mappings, including
"                Fortran Package Manager (fpm) and project-wide tools
"########################################################################

" Plug mappings
nnoremap <buffer> <silent> <Plug>(vimf90-compile)        :call makes#Fcompile()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-exe)            :call makes#Fexe()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-run)            :call makes#Frun()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-cla)            :call makes#Cla()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-dbg)            :call makes#Fdbg()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-make)           :call makes#MakeRun()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-makeprop)       :call makes#MakeCla()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-makeproj)       :call makes#MakeProj()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-fpm-build)      :call fpm#build()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-fpm-run)        :call fpm#run()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-fpm-test)       :call fpm#test()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-project-build)  :call project#build()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-tags)           :call project#generate_tags()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-find-module)    :call project#find_module('')<CR>

" User commands - Core
command! -buffer -bar -nargs=* FortranCompile     call makes#Fcompile(<f-args>)
command! -buffer -bar -nargs=* FortranExe         call makes#Fexe(<f-args>)
command! -buffer -bar          FortranRun         call makes#Frun()
command! -buffer -bar          FortranArgs        call makes#Cla()
command! -buffer -bar          FortranDebug       call makes#Fdbg()
command! -buffer -bar          FortranMake        call makes#MakeRun()
command! -buffer -bar          FortranMakeArgs    call makes#MakeCla()
command! -buffer -bar          FortranMakeProj    call makes#MakeProj()

" User commands - Fortran Package Manager (fpm)
command! -buffer -nargs=* -complete=customlist,fpm#complete FortranFpm call fpm#command(<q-args>)
command! -buffer -bar -nargs=* FortranFpmBuild    call fpm#build(<q-args>)
command! -buffer -bar -nargs=* FortranFpmRun      call fpm#run(<q-args>)
command! -buffer -bar -nargs=* FortranFpmTest     call fpm#test(<q-args>)
command! -buffer -bar -nargs=? FortranFpmNew      call fpm#new(<q-args>)

" User commands - Multi-file Project Tools
command! -buffer -bar -nargs=* FortranProjectBuild call project#build(<q-args>)
command! -buffer -bar          FortranProjectRoot  echo project#find_root()
command! -buffer -bar          FortranTags         call project#generate_tags()
command! -buffer -bar -nargs=? FortranFindModule   call project#find_module(<q-args>)

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
let s:cmds = [
      \ 'FortranCompile', 'FortranExe', 'FortranRun', 'FortranArgs', 'FortranDebug',
      \ 'FortranMake', 'FortranMakeArgs', 'FortranMakeProj',
      \ 'FortranFpm', 'FortranFpmBuild', 'FortranFpmRun', 'FortranFpmTest', 'FortranFpmNew',
      \ 'FortranProjectBuild', 'FortranProjectRoot', 'FortranTags', 'FortranFindModule'
      \ ]
let s:delcmds = join(map(s:cmds, '"delcommand " . v:val'), ' | ')

let s:plugs = [
      \ '<Plug>(vimf90-compile)', '<Plug>(vimf90-exe)', '<Plug>(vimf90-run)',
      \ '<Plug>(vimf90-cla)', '<Plug>(vimf90-dbg)', '<Plug>(vimf90-make)',
      \ '<Plug>(vimf90-makeprop)', '<Plug>(vimf90-makeproj)',
      \ '<Plug>(vimf90-fpm-build)', '<Plug>(vimf90-fpm-run)', '<Plug>(vimf90-fpm-test)',
      \ '<Plug>(vimf90-project-build)', '<Plug>(vimf90-tags)', '<Plug>(vimf90-find-module)'
      \ ]
let s:unplugs = join(map(s:plugs, '"silent! nunmap <buffer> " . v:val'), ' | ')

let b:undo_ftplugin = (exists('b:undo_ftplugin') ? b:undo_ftplugin . ' | ' : '') . s:delcmds . ' | ' . s:unplugs
