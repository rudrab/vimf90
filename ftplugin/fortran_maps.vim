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
" Description: Mappings! This file do not contain any new program. 
" It just calls functions defined in other fils.

:execute 'imap `prg prg' . g:UltiSnipsExpandTrigger . '<Esc>gg=G<C-j>'
:execute 'imap `mod mod' . g:UltiSnipsExpandTrigger . '<Esc>gg=G<C-j>'
:execute 'imap `sub sub' . g:UltiSnipsExpandTrigger . '<Esc>gg=G<C-j>'
:execute 'imap `fun fun' . g:UltiSnipsExpandTrigger . '<Esc>gg=G<C-j>'
inoremap <leader>call call <C-R>=GetComp("subroutine")<CR>
inoremap <leader>use use <C-R>=GetComp("module")<CR>
nnoremap <leader>amk :call MakeAMake()<CR> 
nnoremap <leader>asc :call MakeAConf()<CR> 
autocmd QuitPre *.f90 silent! exe "1," . 10 . "g/Last Modified :.*/s/Last Modified :.*/Last Modified : " .strftime("%c")
