" part of vimf90+
" state.vim: completes some most used statements and declarations 
" of fortran90+
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
