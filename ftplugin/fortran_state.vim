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
" of fortran90+Formatting
"

" Check python modules and install{{{1
if !executable('fprettify') || !executable('fortls') || !executable('unidecode')
  :let choice =confirm("Some python dependencies doesn't exists! Install them?", "&Yes\n&No(use fallback)")
  if !executable('fprettify')
    :call install_deps#install_fprettify() 
  endif
  if !executable('fortls')
    :call install_deps#install_fortls() 
  endif
  if !executable('unidecode')
    :call install_deps#install_unidecode() 
  endif
endif
"}}}

" Options {{{2
let b:fprettify_options = get(g:, "fprettify_options", "--silent")
let b:fortran_leader = get(g:, "fortran_leader", "\`")
" b:fortran_linter 0: Lint on the fly; 1: Lint on BufWrite; 2: use fprettify; -1: No Lint atall 
let b:fortran_linter = get(g:, "fortran_linter", 1)   
"}}}


" Linting options {{{3
if  b:fortran_linter == 0  " Check on the fly, not recommended {{{4
  inoremap <expr> = stridx('</=>',getline(".")[col(".")-3]) >= 0 ? "<bs>= " : getline(".")[col(".")-2] =~ '\s' ? "= " : "="
  inoremap <expr> > stridx('</=>',getline(".")[col(".")-3]) >= 0 ? "<bs>> " : getline(".")[col(".")-2] =~ '\s' ? "> " : ">"
  inoremap <expr> + getline(".")[col(".")-2] =~ '\s' ? "+ " : "+" 
  inoremap <expr> - getline(".")[col(".")-2] =~ '\s' ? "- " : "-"
  inoremap <expr> * getline(".")[col(".")-2] =~ '\s' ? "* " : "*"
  inoremap <expr> / getline(".")[col(".")-2] =~ '\s' ? "/ " : "/"
  "inoremap < expr> / getline(".")[col(".")-2] =~ '[[:blank:])]' ? "/ " : "/"
  "}}}
elseif b:fortran_linter == 1  " Check on save, default {{{5
  au BufWritePre <buffer> silent! :%s/\v(\w) ?(\+|\-|\/|\*|\*\*) ?(\w|-)/\1\2\3/g   " No space between arithmetics
  au BufWritePre <buffer> silent! :%s/\v(\w) ?(\>\=|\<\=|\/\=|\=|\=\=|\>|\<) ?(\w|-)/\1 \2 \3/g  " Space between equals
  au BufWritePre <buffer> silent! :%s/\v(\w) ?(\c\.eq\.|\c\.ne\.|\c\.gt\.|\c\.lt\.|\c\.ge\.|\c\.le\.) ?(\w|-)/\1 \2 \3/g
  au BufWritePre <buffer> silent! :%s/\v(\w) ?(\c\.and\.|\c\.not\.|\c\.or\.|\c\.eqv\.|\c\.neqv\.) ?(\w|-)/\1 \2 \3/g
  au BufWritePre <buffer> silent! :%s/\v(\w|\)) ?(\,|\;) ?/\1\2 \3/g           " comma and semicolon
  au BufWritePre <buffer> silent! :%s/\v(\w|\)) ?(\:\:) ?(\w|-)/\1\2 \3/g     " `::`
  au BufWritePre <buffer> silent! :%s/\v(\w|\)) ?(!) ?(\w|-)/\1  \2 \3/g       " inline comment
  "}}}
elseif b:fortran_linter == 2 " use fprettify{{{6
  au BufWritePre <buffer> :execute 'silent %!fprettify ' . g:fprettify_options
  "}}}
endif
"}}}

" Declarations: {{{7
" :execute  'inoremap'  b:fortran_leader.'wr'    "pr<c-r>=UltiSnips#ExpandSnippet()<cr>"
" :execute  'inoremap'  b:fortran_leader.'rd'    "read<c-r>=UltiSnips#ExpandSnippet()<cr>"
" :execute  'inoremap'  b:fortran_leader.'re'    "real<c-r>=UltiSnips#ExpandSnippet()<cr>"
" :execute  'inoremap'  b:fortran_leader.'int'   "int<c-r>=UltiSnips#ExpandSnippet()<cr>"
" :execute  'inoremap'  b:fortran_leader.'char'  "char<c-r>=UltiSnips#ExpandSnippet()<cr>"
" :execute  'inoremap'  b:fortran_leader.'dim'   "dim<c-r>=UltiSnips#ExpandSnippet()<cr>"
" :execute  'inoremap'  b:fortran_leader.'par'   "par<c-r>=UltiSnips#ExpandSnippet()<cr>"
" :execute  'inoremap'  b:fortran_leader.'sle'   "sle<c-r>=UltiSnips#ExpandSnippet()<cr>"
" :execute  'inoremap'  b:fortran_leader.'prg'   "prg<c-r>=UltiSnips#ExpandSnippet()<cr>"
" :execute  'inoremap'  b:fortran_leader.'mod'   "mod<c-r>=UltiSnips#ExpandSnippet()<cr>"
" :execute  'inoremap'  b:fortran_leader.'sub'   "sub<c-r>=UltiSnips#ExpandSnippet()<cr>"
" :execute  'inoremap'  b:fortran_leader.'fun'   "fun<c-r>=UltiSnips#ExpandSnippet()<cr>"
"}}}
