"########################################################################
" File: fortran_maps.vim
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
"########################################################################

":execute 'imap `prg prg' . g:UltiSnipsExpandTrigger . '<Esc>gg=G<C-j>'
":execute 'imap `mod mod' . g:UltiSnipsExpandTrigger . '<Esc>gg=G<C-j>'
":execute 'imap `sub sub' . g:UltiSnipsExpandTrigger . '<Esc>gg=G<C-j>'
":execute 'imap `fun fun' . g:UltiSnipsExpandTrigger . '<Esc>gg=G<C-j>'


inoremap <leader>call  call <C-o>:set completefunc=GetSubroutine<CR><C-x><C-u>
inoremap <leader>use  use <C-o>:set completefunc=GetModule<CR><C-x><C-u>

nnoremap    <leader>amk     :call MakeMake()<CR> 
nnoremap    <leader>asc     :call MakeConf()<CR>
nnoremap    <leader>sys     :call GenSys()<CR>
nnoremap    <leader>mk      :call Make()<CR>

nnoremap    <leader>cc      :call Compile()<CR>
nnoremap    <leader>cl      :call Link()<CR>
noremap     <leader>cr      :call Run()<CR>
noremap     <leader>ca      :call CLArgs()<CR>

" inoremap `prg               <Esc>:call Prog("prg")<cr><CR><Esc>gg=G<C-j>``
" nnoremap `prg               :call Prog("prg")<cr><CR><Esc>gg=G<C-j>
" inoremap `mod               <Esc>:call Prog("mod")<cr><CR><Esc>gg=G<c-j>``
" nnoremap `mod               :call Prog("mod")<cr><CR><Esc>gg=G<C-j>
" inoremap `sub               <Esc>:call Prog("sub")<cr><CR><Esc>gg=G<C-j>``
" nnoremap `sub               :call Prog("sub")<cr><CR><Esc>gg=G<C-j>
" inoremap `fun               <Esc>:call Prog("fun")<cr><CR><Esc>gg=G<C-j>``
" nnoremap `fun               :call Prog("fun")<cr><CR><Esc>gg=G<C-j>

inoremap `prg prg<c-r>=UltiSnips#ExpandSnippet()<cr>
inoremap `mod mod<c-r>=UltiSnips#ExpandSnippet()<cr>
inoremap `sub sub<c-r>=UltiSnips#ExpandSnippet()<cr>
inoremap `fun fun<c-r>=UltiSnips#ExpandSnippet()<cr>



"autocmd BufUnload *.f90 silent! exe "1," . 10 . "g/Last Modified :.*/s/Last Modified :.*/Last Modified : " .strftime("%c")
"autocmd Bufwritepre,filewritepre *.f90 exe "1," . 10 . "g/Last Modified :.*/s/Last Modified :.*/Last Modified : " .strftime("%c")
au BufWrite *.f90 let b:update_modified = 1
au BufUnload *.f90 silent! if exists('b:update_modified') | exe "1," . 10 . "g/Last Modified :.*/s/Last Modified :.*/Last Modified : " .strftime("%c")| fi
