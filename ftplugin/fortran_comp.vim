" File: comp.vim
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
 

function! GetComp(arg)
"if ! exists('g:modpath')
  "let g:modpath = 'src,,.'
"endif
python << EOF
import vim
import os
flsts = [' ']
path = "."
for dirs, subdirs, files in os.walk(path):
    for tfile in files:
        if tfile.endswith(('f90', 'F90', 'f', 'F')):
            ofile = open(dirs+'/'+tfile)
            for line in ofile:
                if line.lower().strip().startswith(vim.eval("a:arg")):
                    modname = line.split()[1]
                    flsts.append(modname)
vim.command("let flstsI = %s"%flsts)                    
EOF
call complete(col('.'), flstsI)
return ''
endfunction
