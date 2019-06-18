" File: fortran_state.vim
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
" Description:  completes some most used statements and declarations 
" of fortran90+ Formatting
"
" For the laziest people, add a space around operators {{{1
inoremap <expr> = stridx('</=>',getline(".")[col(".")-3]) >= 0 ? "<bs>= " : getline(".")[col(".")-2] =~ '\s' ? "= " : "="
inoremap <expr> > stridx('</=>',getline(".")[col(".")-3]) >= 0 ? "<bs>> " : getline(".")[col(".")-2] =~ '\s' ? "> " : ">"
inoremap <expr> + getline(".")[col(".")-2] =~ '\s' ? "+ " : "+" 
inoremap <expr> - getline(".")[col(".")-2] =~ '\s' ? "- " : "-"
inoremap <expr> * getline(".")[col(".")-2] =~ '\s' ? "* " : "*"
inoremap <expr> / getline(".")[col(".")-2] =~ '\s' ? "/ " : "/"
"inoremap <expr> / getline(".")[col(".")-2] =~ '[[:blank:])]' ? "/ " : "/"

" Declarations: {{{1
" call IMAP ('<localleader>wr',  'write(<++>,*)<++>',           "fortran")
" call IMAP ('<localleader>rd',  'read(<++>,*)<++>',            "fortran")
inoremap <localleader>wr   pr<c-r>=UltiSnips#ExpandSnippet()<cr>
inoremap <localleader>rd read<c-r>=UltiSnips#ExpandSnippet()<cr>
inoremap <localleader>re real<c-r>=UltiSnips#ExpandSnippet()<cr>
inoremap <localleader>int int<c-r>=UltiSnips#ExpandSnippet()<cr>
inoremap <localleader>char char<c-r>=UltiSnips#ExpandSnippet()<cr>
" call IMAP ('<localleader>re',  'real(<++>)::<++>',            "fortran")
" call IMAP ('<localleader>int', 'integer::<++>',               "fortran")
" call IMAP ('<localleader>ch',  'character(len=<++>)::<++>',   "fortran")
call IMAP ('<localleader>dim', 'dimension(<++>)',             "fortran")
call IMAP ('<localleader>par', 'parameter',                   "fortran")
call IMAP ('<localleader>sre', 'selected_real_kind(<++>)',    "fortran")
call IMAP ('<localleader>sie', 'selected_integer_kind(<++>)', "fortran")

"INTRINSIC PROCEDURES:  {{{1
:call IMAP ('<localleader>fab',     'abort',                  "fortran")
:call IMAP ('<localleader>fabs',    'abs(<++>)',              "fortran")
:call IMAP ('<localleader>facc',    'access(<++>,<++>)',      "fortran")
:call IMAP ('<localleader>fach',    'achar(<++>)',            "fortran")
:call IMAP ('<localleader>facos',   'acos(<++>)',             "fortran")
:call IMAP ('<localleader>facosh',  'acosh(<++>)',            "fortran")
:call IMAP ('<localleader>fadl',    'adjustl(<++>)',          "fortran")
:call IMAP ('<localleader>fadr',    'adjustr(<++>)',          "fortran")
:call IMAP ('<localleader>faim',    'aimag(<++>)',            "fortran")
:call IMAP ('<localleader>faint',   'aint(<++>)',             "fortran")
