"########################################################################
" Filename:      makes.vim
" Copyright: Copyright (C) 2019 Rudra Banerjee
" 
"    This program is free software: you can redistribute it and/or modify
"    it under the terms of the GNU General Public License as published by
"    the Free Software Foundation, either version 3 of the License, or
"    (at your option) any later version.
"
"    This program is distributed in the hope that it will be useful,
"    but WITHOUT ANY WARRANTY; without even the implied warranty of
"    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
"    GNU General Public License for more details.
" Date:          03/07/2015
" Description:   Make utility for fortran. 
"                Largely adapted from c.vim
"########################################################################

" Variables {{{1
let s:Compiler = get(g:, "fortran_compiler", "gfortran")
let s:ObjExt    =   '.o'
let s:ModExt    =   '.mod'
let s:ExeExt    =   ''
let s:VimComp   =   'gfortran'
let s:FCFlags   =  get(g:, "fortran_fcflags",   '-Wall  -O0 -c')
let s:FLFlags   =   get(g:, "fortran_flflags",  '-Wall -O0')
let s:OutputGvim=   'vim'
"}}}1

" Compile current buffer {{{1
function! makes#Fcompile()
  let sou = expand("%:p")
  let obj = expand("%:p:r").s:ObjExt
  let s:fortran_comp_success = 0
    "
  setlocal efm=%E%f:%l:%c:,%E%f:%l:,%C,%C%p%*[0123456789^],%ZError:\ %m,%C%.%#
  " Don't process any further if the compilation is up to date
  if filereadable(obj) && (getftime(obj)>getftime(sou))
    echom "'" . obj . "':is up to date"
    let s:fortran_comp_success=1
    return
  endif

  let makeprg_saved = '"' . &makeprg . '"'
  execute "setlocal makeprg=" . s:Compiler
  " let v:statusmsg = ''
  execute "silent make " . s:FCFlags . " " . sou . " -o " . obj

  " Don'r process any further if the compilation was sucessful
  if empty(v:statusmsg)
    echom "'" . obj . "':Compiled successfully"
    let s:fortran_comp_success=1
    return
  endif

  if v:shell_error !=0
    " let &statusline = v:shell_error
    return
  endif
  botright copen
endfunction
"}}}1

" Run executable {{{1
function! makes#Frun()
  let sou = expand("%:p")
  let obj = expand("%:p:r").s:ObjExt
  call makes#Fcompile()
  let s:fortran_link_success =1
  if s:fortran_comp_success==1
    let makeprg_saved = '"' . &makeprg . '"'
    execute "setlocal makeprg=" . s:Compiler
    let s:exe = expand("%:p:r")
    exe "make " .s:FLFlags."  " .obj. " -o ".s:exe
    if v:shell_error !=0
      let &statusline = v:shell_error
      let s:fortran_link_success = 0
      return
    endif
    if s:fortran_link_success==1
      let l:args = exists("b:Clargs") ? b:Clargs : "" 
      exe "!".s:exe. " " . l:args
    endif
  endif
endfunction
"}}}1

" CLArgs: Command Line Argument {{{1
function! makes#Cla()
  let Exe = expand("%:p:t").s:ExeExt
  let sou = expand("%:p")
  if empty(Exe)
    redraw
    echohl WarningMsg | echo "no file name " | echohl None
    return
  endif
  let	prompt	= 'command line arguments for "'.Exe.'" : '
  if exists("b:Clargs")
    let b:Clargs=input(prompt, b:Clargs,"file")
  else
    let b:Clargs=input(prompt,"","file")
  endif
endfunction
"}}}1
