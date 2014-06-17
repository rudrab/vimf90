" part of vimf90+
" state.vim: completes some most used statements and declarations 
" of fortran90+
"
"Formatting
 inoremap <expr> = getline(".")[col(".")-2] =~ '[[:alnum:])]' ? " = " : "=" 
 inoremap <expr> + getline(".")[col(".")-2] =~ '[[:alnum:])]' ? " + " : "+" 
 inoremap <expr> - getline(".")[col(".")-2] =~ '[[:alnum:])]' ? " - " : "-" 

" "declarations 
call IMAP ('`wr',  'write(<++>,*)<++>',           "fortran")
call IMAP ('`rd',  'read(<++>,*)<++>',            "fortran")
call IMAP ('`re',  'real(<++>)::<++>',            "fortran")
call IMAP ('`int', 'integer::<++>',               "fortran")
call IMAP ('`ch',  'character(len=<++>)::<++>',   "fortran")
call IMAP ('`dim', 'dimension(<++>)',             "fortran")
call IMAP ('`par', 'parameter',                   "fortran")
call IMAP ('`sre', 'selected_real_kind(<++>)',    "fortran")
call IMAP ('`sie', 'selected_integer_kind(<++>)', "fortran")

"INTRINSIC PROCEDURES
:call IMAP ('`fab',     'abort',                  "fortran")
:call IMAP ('`fabs',    'abs(<++>)',              "fortran")
:call IMAP ('`facc',    'access(<++>,<++>)',      "fortran")
:call IMAP ('`fach',    'achar(<++>)',            "fortran")
:call IMAP ('`facos',   'acos(<++>)',             "fortran")
:call IMAP ('`facosh',  'acosh(<++>)',            "fortran")
:call IMAP ('`fadl',    'adjustl(<++>)',          "fortran")
:call IMAP ('`fadr',    'adjustr(<++>)',          "fortran")
:call IMAP ('`faim',    'aimag(<++>)',            "fortran")
:call IMAP ('`faint',   'aint(<++>)',             "fortran")

