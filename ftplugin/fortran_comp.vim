"########################################################################
" File: fortran_comp.vim
" Author: Rudra Banerjee (bnrj DOT rudra at gmail.com) 
" Version: 0.2
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
"
" Description: This file completes lists of subprogram
"########################################################################
 
" GetComp: Menu and Sunroutine Completion {{{1
function! GetSubroutine(findstart, base)
if a:findstart
    " locate the start of the word
    let line = getline('.')
    let start = col('.') - 1
    while start > 0 && line[start - 1] =~ '\a'
        let start -= 1
    endwhile
    return start
else
    echomsg '**** completing' a:base
python << EOF
import vim
import os
flsts = []
path = "."
for dirs, subdirs, files in os.walk(path):
    for tfile in files:
        if tfile.endswith(('f90', 'F90', 'f', 'F')):
            ofile = open(dirs+'/'+tfile)
            for line in ofile:
                if line.lower().strip().startswith("subroutine"):
                    modname = line.split()[1]
                    flsts.append(modname)
vim.command("let flstsI = %s"%flsts)                    
EOF
for m in [
      \"alarm()", "date_and_time()", "backtrace", "c_f_procpointer()", "chdir()", "chmod()", 
      \"co_broadcast()", "get_command()", "get_command_argument()", "get_environment_variable()", 
      \"mvbits()", "random_number()", "random_seed()"
      \]
  if m =~ "^" . a:base
    call add(flstsI, m)
  endif
endfor
return flstsI
endif
endfunction



function! GetModule(findstart, base)
if a:findstart
    " locate the start of the word
    let line = getline('.')
    let start = col('.') - 1
    while start > 0 && line[start - 1] =~ '\a'
        let start -= 1
    endwhile
    return start
else
    echomsg '**** completing' a:base
python << EOF
import vim
import os
flsts = []
path = "."
for dirs, subdirs, files in os.walk(path):
    for tfile in files:
        if tfile.endswith(('f90', 'F90', 'f', 'F')):
            ofile = open(dirs+'/'+tfile)
            for line in ofile:
                if line.lower().strip().startswith("module"):
                    modname = line.split()[1]
                    flsts.append(modname)
vim.command("let flstsI = %s"%flsts)                    
EOF
for m in ["ieee_arithmatic", "ieee_exceptions", "ieee_features", 
      \"iso_c_bindings", "iso_fortran_env",  
      \"omp_lib", "omp_lib_kinds"
      \]
  if m =~ "^" . a:base
    call add(flstsI, m)
  endif
endfor
return flstsI
endif
endfunction
"}}}

"Prg: Expand snippets {{{!
let s:plugin_dir=filter(split(&rtp, ','), 'v:val =~ "/vimf90"')[0]
let s:templatedir=s:plugin_dir . '/templates/'
function! Prog(arg)
  execute 'r ' . s:templatedir . a:arg . '.txt'
  %substitute#\[:EVAL:\]\(.\{-\}\)\[:END:\]#\=eval(submatch(1))#ge
endfunction
"}}}
