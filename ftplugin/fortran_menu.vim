"########################################################################
" File: fortran_menu.vim
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
" Description: Create menu  
"########################################################################
if !exists('g:Fortran_menumode')
  let g:Fortran_menumode = 1
endif

if has('gui_running') && has('menu')
  let s:menu_root = 'Fortran'

  if g:Fortran_menumode == 1
    " This is how to set the variables
    exe 'anoremenu  Fortran&90.&Compile.&Compile<Tab>'.b:fortran_compile                ':call Compile()<CR>'
    exe 'inoremenu  Fortran&90.&Compile.&Compile<Tab>'.b:fortran_compile                '<C-C>:call Compile()<CR>'
    exe 'anoremenu  Fortran&90.&Compile.&Compile\ and\ Run<Tab>'.b:fortran_run          ':call Run()<CR>'
    exe 'inoremenu  Fortran&90.&Compile.&Compile\ and\ Run<Tab>'.b:fortran_run          '<C-C>:call Run()<CR>'
    exe 'anoremenu  Fortran&90.&Compile.&Comand\ Line\ Arguments<Tab>'.b:fortran_cla    ':call CLArgs()<CR>'
    exe 'inoremenu  Fortran&90.&Compile.&Comand\ Line\ Arguments<Tab>'.b:fortran_cla    '<C-C>:call CLArgs()<CR>'
    exe 'anoremenu  Fortran&90.&Compile.&Run\ &Debugger<Tab>'.b:fortran_dbg             ':call Debug()<CR>'
    exe 'inoremenu  Fortran&90.&Compile.&Run\ &Debugger<Tab>'.b:fortran_dbg             '<C-C>:call Debug()<CR>'
    an  &Fortran90.&Compile.----                                        " 
    exe 'anoremenu  Fortran&90.&Make.&Make<Tab>'.b:fortran_make                         ':call Make()<CR>'
    exe 'inoremenu  Fortran&90.&Make.&Make<Tab>'.b:fortran_make                         '<C-C>:call Make()<CR>'
    exe 'anoremenu  Fortran&90.&Make.Make\ &Properties<Tab>'.b:fortran_makeProp         ':call MakeProperties()<CR>'
    exe 'inoremenu  Fortran&90.&Make.Make\ &Properties<Tab>'.b:fortran_makeProp         '<C-C>:call MakeProperties()<CR>'
    an  &Fortran90.&Compile.----                                        " 
    exe 'anoremenu  Fortran&90.&Make.Generate\ &Project<Tab>'.b:fortran_genProj         ':call MakeProject()<CR>'
    exe 'inoremenu  Fortran&90.&Make.Generate\ &Project<Tab>'.b:fortran_genProj         '<C-C>:call MakeProject()<CR>'
    " exe 'anoremenu  Fortran&90.&Make.Make\ &Clean<Tab>\\mkc                           :call MakeClean()<CR>'
    " exe 'inoremenu  Fortran&90.&Make.Make\ &Clean<Tab>\\mkc                      <C-C>:call MakeClean()<CR>'
    " an  &Fortran90.&Compile.--sep0--                                        " 
    " an  Fortran&90.&Compile.&Generate\ configure\.ac<Tab>autoscan       :call MakeConf()<CR>
    " an  Fortran&90.&Compile.&Generate\ Makefile\.am<Tab>Experimental    :call MakeMake()<CR>
    " an  &Fortran90.--sep0--                                            <Nop>  
    " an  &Fortran90.&Blocks.&Program<Tab>`prg                            :call Prog("prg")<cr><CR><Esc>gg=G<C-j>
    " an  &Fortran90.&Blocks.&Module<Tab>`mod                             :call Prog("mod")<cr><CR><Esc>gg=G<C-j>
    "an  &Fortran90.&Blocks.&Subroutine<Tab>`sub                        `sub  
    "an  &Fortran90.&Blocks.&Function<Tab>`fun                          `fun  
    an  &Fortran90.--sep1--                                             <Nop> 
    "an  &Fortran90.&integer<Tab>                                        :call IMAP ('`int', 'integer::',"fortran")
    an  &Fortran90.&Help<Tab>VimF90\ Help                               :h vimf90.txt<CR>  
  endif
endif
