"########################################################################
" Filename:      fortran_make.vim
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
let s:Compiler = get(g:, "fortran_compiler", "gfortran")
let s:ObjExt    =   '.o'
let s:ModExt    =   '.mod'
let s:ExeExt    =   ''
let s:VimComp   =   'gfortran'
let s:FCFlags   =   '-Wall -g -O0 -c'
let s:FLFlags   =   '-Wall -g -O0'
let s:OutputGvim=   'vim'

function! Compile()
  :call makes#Fcompile()
endfunction

function! Run()
  :call makes#Frun()
endfunction

function! CLArgs()
  :call makes#Cla()
endfunction

function! Debug()
  :call makes#Dbg()
endfunction

function! Make()
  :call makes#MakeRun()
endfunction

function! MakeProperties()
  :call makes#MakeCla()
endfunction

function! MakeProject()
  :call makes#MakeProj()
endfunction
