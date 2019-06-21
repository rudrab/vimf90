" File: fortran_state.vim
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
" Description:  completes some most used statements and declarations 
" of fortran90+ Formatting
"
let g:VimF90Leader = get(g:, "VimF90Leader", "\`")
" g:VimF90Linter 0: Lint on the fly; 1: Lint on BufWrite; -1: No Lint atall {{{
let g:VimF90Linter = get(g:, "VimF90Linter", 0)   
if  g:VimF90Linter == 0  " Check on the fly, not recommended {{{
  inoremap <expr> = stridx('</=>',getline(".")[col(".")-3]) >= 0 ? "<bs>= " : getline(".")[col(".")-2] =~ '\s' ? "= " : "="
  inoremap <expr> > stridx('</=>',getline(".")[col(".")-3]) >= 0 ? "<bs>> " : getline(".")[col(".")-2] =~ '\s' ? "> " : ">"
  inoremap <expr> + getline(".")[col(".")-2] =~ '\s' ? "+ " : "+" 
  inoremap <expr> - getline(".")[col(".")-2] =~ '\s' ? "- " : "-"
  inoremap <expr> * getline(".")[col(".")-2] =~ '\s' ? "* " : "*"
  inoremap <expr> / getline(".")[col(".")-2] =~ '\s' ? "/ " : "/"
  "inoremap <expr> / getline(".")[col(".")-2] =~ '[[:blank:])]' ? "/ " : "/"
  "}}}
elseif g:VimF90Linter == 1  " Check on save, default {{{
  au BufWritePre *.f90 silent! :%s/\v(\w) ?(\+|-|\*|\/|\>\=|\<\=|\/\=|\=|\=\=|\*\*|\>|\<) ?(\w|-)/\1 \2 \3/
  au BufWritePre *.f90 silent! :%s/\v(\w) ?(\c\.eq\.|\c\.ne\.|\c\.gt\.|\c\.lt\.|\c\.ge\.|\c\.le\.) ?(\w|-)/\1 \2 \3/
  au BufWritePre *.f90 silent! :%s/\v(\w) ?(\c\.and\.|\c\.not\.|\c\.or\.|\c\.eqv\.|\c\.neqv\.) ?(\w|-)/\1 \2 \3/
  au BufWritePre *.f90 silent! :%s/\v(\w|\)) ?(\,) ?/\1\2 \3/g
  au BufWritePre *.f90 silent! :%s/\v(\w|\)) ?(\:\:) ?(\w|-)/\1 \2 \3/g
  "}}}
endif
"}}}

" Declarations: {{{1
:execute 'inoremap' g:VimF90Leader.'wr'      "pr<c-r>=UltiSnips#ExpandSnippet()<cr>"
:execute 'inoremap' g:VimF90Leader.'rd'    "read<c-r>=UltiSnips#ExpandSnippet()<cr>"
:execute 'inoremap' g:VimF90Leader.'re'    "real<c-r>=UltiSnips#ExpandSnippet()<cr>"
:execute 'inoremap' g:VimF90Leader.'int'    "int<c-r>=UltiSnips#ExpandSnippet()<cr>"
:execute 'inoremap' g:VimF90Leader.'char'  "char<c-r>=UltiSnips#ExpandSnippet()<cr>"
:execute 'inoremap' g:VimF90Leader.'dim'    "dim<c-r>=UltiSnips#ExpandSnippet()<cr>"
:execute 'inoremap' g:VimF90Leader.'par'    "par<c-r>=UltiSnips#ExpandSnippet()<cr>"
:execute 'inoremap' g:VimF90Leader.'sle'    "sle<c-r>=UltiSnips#ExpandSnippet()<cr>"
"}}}
