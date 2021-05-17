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
let b:fortran_dep_install = get(g:, "fortran_dep_install", 1)
if b:fortran_dep_install != 3
  if !executable('fprettify') || !executable('fortls') || !executable('unidecode')
    :let choice = confirm("Some python dependencies doesn't exists! Install them?\nIf you don't want to be asked again, in vimrc, put \n'let fortran_dep_install=3'", "&Yes\n&No")
    if choice == 1
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
  " Use curpos to save and restore the cursor position before and after linting.
  au BufWritePre <buffer> :let curpos = getpos('.') | silent! %s/\v(\w) ?(\+|\-|\/|\*|\*\*) ?(\w|-)/\1\2\3/g | call setpos('.', curpos)   " No space between arithmetics
  au BufWritePre <buffer> :let curpos = getpos('.') | silent! %s/\v(\w) ?(\>\=|\<\=|\/\=|\=|\=\=|\>|\<) ?(\w|-)/\1 \2 \3/g | call setpos('.', curpos)  " Space between equals
  au BufWritePre <buffer> :let curpos = getpos('.') | silent! %s/\v(\w) ?(\c\.eq\.|\c\.ne\.|\c\.gt\.|\c\.lt\.|\c\.ge\.|\c\.le\.) ?(\w|-)/\1 \2 \3/g | call setpos('.', curpos)
  au BufWritePre <buffer> :let curpos = getpos('.') | silent! %s/\v(\w) ?(\c\.and\.|\c\.not\.|\c\.or\.|\c\.eqv\.|\c\.neqv\.) ?(\w|-)/\1 \2 \3/g | call setpos('.', curpos)
  au BufWritePre <buffer> :let curpos = getpos('.') | silent! %s/\v(\w|\)) ?(\,|\;) ?/\1\2 \3/g | call setpos('.', curpos)           " comma and semicolon
  au BufWritePre <buffer> :let curpos = getpos('.') | silent! %s/\v(\w|\)) ?(\:\:) ?(\w|-)/\1\2 \3/g | call setpos('.', curpos)     " `::`
  au BufWritePre <buffer> :let curpos = getpos('.') | silent! %s/\v(\w|\)) ?(!) ?(\w|-)/\1  \2 \3/g | call setpos('.', curpos)       " inline comment
  "}}}
elseif b:fortran_linter == 2 " use fprettify{{{6
  " Use curpos to save and restore the cursor position before and after linting.
  au BufWritePre <buffer> :let curpos = getpos('.') | execute 'silent %!fprettify ' . g:fprettify_options | call setpos('.', curpos)
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
