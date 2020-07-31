"########################################################################
" File: fortran_maps.vim
" Author: Rudra Banerjee (bnrj DOT rudra at gmail.com) 
" Version: 0.2
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
"
" Description: Mappings! This file do not contain any new program. 
" It just calls functions defined in other fils.
"########################################################################

":execute 'imap `prg prg' . g:UltiSnipsExpandTrigger . '<Esc>gg=G<C-j>'
":execute 'imap `mod mod' . g:UltiSnipsExpandTrigger . '<Esc>gg=G<C-j>'
":execute 'imap `sub sub' . g:UltiSnipsExpandTrigger . '<Esc>gg=G<C-j>'
":execute 'imap `fun fun' . g:UltiSnipsExpandTrigger . '<Esc>gg=G<C-j>'


" inoremap <leader>call  call <C-o>:set completefunc=GetSubroutine<CR><C-x><C-u>
" inoremap <leader>use  use <C-o>:set completefunc=GetModule<CR><C-x><C-u>

let b:fortran_compile = get(g:,"fortran_complie", "\<leader\>cc")
let b:fortran_run = get(g:,"fortran_run", "\<leader\>cr")
let b:fortran_run = get(g:,"fortran_make", "\<leader\>mk")

exe 'nnoremap'    b:fortran_make     ':call MakeMake()<CR>'
nnoremap    <leader>asc     :call MakeConf()<CR>
nnoremap    <leader>sys     :call GenSys()<CR>
nnoremap    <leader>mk      :call Make()<CR>

exe 'nnoremap'    b:fortran_compile      ':call Compile()<CR>'
nnoremap    <leader>cl      :call Link()<CR>
exe 'noremap'     b:fortran_run      ':call Run()<CR>'
noremap     <leader>ca      :call CLArgs()<CR>

autocmd Bufwritepre,filewritepre *.f90 exe "%g/Last Modified:.*/s/Last Modified:.*/Last Modified: " .strftime("%c")
