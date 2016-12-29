"########################################################################
" Filename:      fortran_make.vim
" Copyright: Copyright (C) 2015 Rudra Banerjee
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
"
"Defaults: global values {{{1
let s:Compiler  =   'gfortran'
let s:ObjExt    =   '.o'
let s:ModExt    =   '.mod'
let s:ExeExt    =   ''
let s:VimComp   =   'gfortran'
let s:FCFlags   =   '-Wall -g -O0 -c'
let s:FLFlags   =   '-Wall -g -O0'
let s:OutputGvim=   'vim'
"}}}
" CheckMain: Check if current buffer is the main program {{{1
function! CheckMain()
  return search('^\s*/Program\C',"cnw")
endfunction

" Compile: compile the current file    {{{1
function! Compile()
  exe ":cclose"
  exe ":update"

  let sou = expand("%:p")
  let obj = expand("%:p:r").s:ObjExt

  if !filereadable(obj) || (filereadable(obj) && (getftime(obj)<getftime(sou)))
    let makeprg_saved = '"'.&makeprg.'"'
    exe "setlocal makeprg=".s:Compiler
    let v:statusmsg = ''
    exe "make ".s:FCFlags. " " .sou. " -o " .obj
    if empty(v:statusmsg)
      :let &statusline = "'".obj."':Compiled successfully"
    endif
    if v:shell_error !=0
      :let &statusline = v:shell_error
    endif
    ":redraw!
    exe ":botright copen"
  else
    :let &statusline = "'".obj."':is up to date"
  endif
endfunction 

" Link: Compile and link {{{1
function! Link()
  "compile first
  let sou = expand("%:p")
  let obj = expand("%:p:r").s:ObjExt
  let Exe = expand("%:p:r").s:ExeExt
  if empty(glob(obj))
    call Compile()
  endif
  if filereadable(Exe)                      &&
        \ filereadable(obj)                 &&
        \ filereadable(sou)                 &&
        \ (getftime(Exe) >= getftime(obj))  &&
        \ (getftime(obj) >= getftime(sou))
    :let &statusline = " '".exe."' is up to date "
    return
  endif

  let v:statusmsg = ""
    let makeprg_saved = '"'.&makeprg.'"'
    exe "setlocal makeprg=".s:Compiler
  exe "make " .s:FLFlags." ".obj. " -o " .Exe
  if v:shell_error != 0
    :let &statusline="Error in linking '" .Exe. "'"
    exe ":cclose"
    exe ":update"
    exe ":botright copen"
  else
    :let &statusline="'".Exe."': Successfully Linked"
  endif
endfunction


let s:OubufName="Fortran-Output"
let s:OubufNum="-1"
let s:Runmsg1="' does not exist or is not executable or object/source older then executable"
let s:Runmsg2="' does not exist or is not executable"

" Run: Compile, Link and Run executable {{{1
function! Run()
  exe ":cclose"
  exe ":update"
  let sou               = expand("%:p")
  let obj               = expand("%:p:r").s:ObjExt
  let exe               =""
  " expand("%:p:r").s:ExeExt
  let l:arguments       = exists("b:Clargs") ? b:Clargs : ''
  let l:currentbuffer   = bufname("%")
  if empty(glob(exe))
    let exe               = expand("%:p:r").s:ExeExt
  endif

  if empty(glob(exe))
    call Link()
  endif
  exe ':enew |.!'.exe." ".l:arguments
endfunction

" CLArgs: Command Line Argument {{{1
function! CLArgs()
  let Exe = expand("%:p:t").s:ExeExt
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
let s:Fmakefile=" "
" SearchMake: Search for the proper Makefile   {{{1
function! SearchMake()
  let s:Fmakefile= input("Search Makefile: ", getcwd(),"file")
endfunction
"}}}1
" Make: run make {{{1
function! Make()
  if empty(glob("\cmakefile")) && s:Fmakefile == " "
    let smak =inputlist(["Choose Makefile:", '1. Choose Makefile',
          \'2. Create Makefile Using Autotool'])
    if smak == 1
      call SearchMake()
    elseif smak == 2
      if empty("configure")
        call MakeConf()
      endif
      call MakeMake()
      :let &statusline="Rudimentary configure.scan and Makefile.am.gen created. Check before tunning them"
      return
    endif
  endif
  exe ":cclose"
  exe ":wa"
  if s:Fmakefile == " "
    exe ":make -s"
  else
    exe ':lchdir '.fnamemodify(s:Fmakefile, ":p:h")
    exe ':make -f  '.s:Fmakefile
    exe ':lchdir -'
  endif
  exe ":botright cwindow"
  if getqflist() == []
    :let &statusline="Makefile compiled successfully"
    :let exe = expand("%:p:h:t")
  endif
endfunction  

" MakeClean: Make clean{{{1
function! MakeClean()
  echo "'".s:Fmakefile."'"
  if s:Fmakefile == ""
    exe ":make clean"
  else
    exe ':lchdir '.fnamemodify( s:Fmakefile, ":p:h")
    exe ':make -f '.s:Fmakefile.' clean'
    exe ':lchdir -'
  endif
endfunction

"FProject: Create a project {{{1
function! FProject()
  let s:Prdir = input("Create new project: ", getcwd(), "file")
  exe ":!mkdir -p ".s:Prdir
  exe ":lchdir ".s:Prdir
  exe ":!mkdir help src"
  exe ":!touch ChangeLog README LICENSE"
  exe ":lchdir -"
endfunction

let b:Rdir = " "
"MakeConf: Autoscan to create configure.scan {{{1
function! MakeConf()
  let b:Rdir = input("Project root folder: ", ".", 'file')
  exe ":!autoscan ".b:Rdir
endfunction

"MakeMake: Generate Makefile.gen {{{1
function! MakeMake()
  if b:Rdir == " "
    let b:Rdir = input("Project root folder: ", ".", 'file')
  endif
  exe ":lchdir ".b:Rdir
  :let b:Fnm=[]
  let b:Sdir = input("Choose source dir: ", ".", "dir")
  echo "\n"
  for i in split(b:Sdir)
    :let b:Fnm += split(globpath(i,"*"),"\n")
  endfor
  :let b:Nbin=expand('%:p:h:t')
python<<EOF
import vim
import os
binname = vim.eval("b:Nbin")
dlsts=[]
snm = ""
ofn="Makefile.am"
if os.path.isfile("Makefile.am"):
  ofn="Makefile.am.gen"
pFnm = vim.eval("b:Sdir").strip() 
dlsts=pFnm.split()
for sdirs in dlsts:
  for dirs, subdirs, files in os.walk(sdirs):
    for srcs in files:
      if srcs.endswith((".f90", "f")):
        relDir = os.path.relpath(sdirs)
        relFile = os.path.join(relDir, srcs)
        snm += relFile+" "
        with open(ofn,"w") as mak:
          mak.write("#This file is generated by vimf90 plugin\n#This is a bare bone Makefile.am file\n")
          mak.write("bin_PROGRAMS =\t"+binname+"\n")
          mak.write(binname+"_SOURCES =\t"+snm+"\n")
          mak.write("if FOUND_MAKEDEPF90\ndepend depend.mk:\n\tmakedepf90 $("+binname+"_SOURCES) >depend.mk\n")
          mak.write("@am__include@ @am__quote@depend.mk@am__quote@\n")
          mak.write("else\n$(warning Create the dependencies Manually or try installing makedepf90)\n")
          mak.write("$(error  like ./src/main.o:./src/main.f90)\n")
          mak.write("endif\n")
          mak.write(binname+"_LDADD = \nEXTRA_DIST= \nCLEANFILES =*.mod,*.o")
if os.path.isfile(ofn):
  print("File "+ofn+" created. Check it before proceed.")
EOF
endfunction

function! CFile(A,L,P)
  "return split(globpath(b:Rdir, a:A),"\n")
  return split(globpath(b:Rdir, '*/'),"\n")
endfunction

"function! CFile(findstart, base)
"  if a:findstart
"    " locate the start of the word
"    let line = getline('.')
"    let start = col('.') - 1
"    while start > 0 && line[start - 1] =~ '\a'
"      let start -= 1
"    endwhile
"    return start
"  else
"    " find months matching with "a:base"
"    let res = []
"    for m in split(globpath('b:Rdir', "*"),"\n")
"      if m =~ '^' . a:base
"        call add(res, m)
"      endif
"    endfor
"    return res
"  endif
"endfunction
""set completefunc=CFile
