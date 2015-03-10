inoremap \use use <C-R>=GetComp("module")<CR>
inoremap \call call <C-R>=GetComp("subroutine")<CR>
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
        if tfile.endswith('f90'):
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
