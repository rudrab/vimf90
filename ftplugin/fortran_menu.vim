"########################################################################
" File:          ftplugin/fortran_menu.vim
" Author:        Rudra Banerjee (bnrj DOT rudra at gmail.com)
" Version:       0.3
" License:       GPLv3
" Description:   GUI Menu for Fortran tools
"########################################################################

if !exists('g:Fortran_menumode')
  let g:Fortran_menumode = 1
endif

if has('gui_running') && has('menu') && g:Fortran_menumode == 1
  let s:c_comp  = get(b:, 'fortran_compile',  '\cc')
  let s:c_exe   = get(b:, 'fortran_exe',      '\ce')
  let s:c_run   = get(b:, 'fortran_run',      '\cr')
  let s:c_cla   = get(b:, 'fortran_cla',      '\cl')
  let s:c_dbg   = get(b:, 'fortran_dbg',      '\cd')
  let s:c_make  = get(b:, 'fortran_make',     '\mk')
  let s:c_prop  = get(b:, 'fortran_makeProp', '\mp')
  let s:c_proj  = get(b:, 'fortran_genProj',  '\gp')

  execute 'anoremenu Fortran&90.&Compile.&Compile<Tab>' . escape(s:c_comp, ' ') . ' :call makes#Fcompile()<CR>'
  execute 'inoremenu Fortran&90.&Compile.&Compile<Tab>' . escape(s:c_comp, ' ') . ' <C-C>:call makes#Fcompile()<CR>'

  execute 'anoremenu Fortran&90.&Compile.&Generate\ Executable<Tab>' . escape(s:c_exe, ' ') . ' :call makes#Fexe()<CR>'
  execute 'inoremenu Fortran&90.&Compile.&Generate\ Executable<Tab>' . escape(s:c_exe, ' ') . ' <C-C>:call makes#Fexe()<CR>'

  execute 'anoremenu Fortran&90.&Compile.&Compile\ and\ Run<Tab>' . escape(s:c_run, ' ') . ' :call makes#Frun()<CR>'
  execute 'inoremenu Fortran&90.&Compile.&Compile\ and\ Run<Tab>' . escape(s:c_run, ' ') . ' <C-C>:call makes#Frun()<CR>'

  execute 'anoremenu Fortran&90.&Compile.&Command\ Line\ Arguments<Tab>' . escape(s:c_cla, ' ') . ' :call makes#Cla()<CR>'
  execute 'inoremenu Fortran&90.&Compile.&Command\ Line\ Arguments<Tab>' . escape(s:c_cla, ' ') . ' <C-C>:call makes#Cla()<CR>'

  execute 'anoremenu Fortran&90.&Compile.&Run\ Debugger<Tab>' . escape(s:c_dbg, ' ') . ' :call makes#Fdbg()<CR>'
  execute 'inoremenu Fortran&90.&Compile.&Run\ Debugger<Tab>' . escape(s:c_dbg, ' ') . ' <C-C>:call makes#Fdbg()<CR>'

  an &Fortran90.&Compile.---- <Nop>

  execute 'anoremenu Fortran&90.&Make.&Make<Tab>' . escape(s:c_make, ' ') . ' :call makes#MakeRun()<CR>'
  execute 'inoremenu Fortran&90.&Make.&Make<Tab>' . escape(s:c_make, ' ') . ' <C-C>:call makes#MakeRun()<CR>'

  execute 'anoremenu Fortran&90.&Make.Make\ &Properties<Tab>' . escape(s:c_prop, ' ') . ' :call makes#MakeCla()<CR>'
  execute 'inoremenu Fortran&90.&Make.Make\ &Properties<Tab>' . escape(s:c_prop, ' ') . ' <C-C>:call makes#MakeCla()<CR>'

  an &Fortran90.&Make.---- <Nop>

  execute 'anoremenu Fortran&90.&Make.Generate\ &Project<Tab>' . escape(s:c_proj, ' ') . ' :call makes#MakeProj()<CR>'
  execute 'inoremenu Fortran&90.&Make.Generate\ &Project<Tab>' . escape(s:c_proj, ' ') . ' <C-C>:call makes#MakeProj()<CR>'

  an &Fortran90.--sep1-- <Nop>
  an &Fortran90.&Format\ Buffer :call makes#format_buffer()<CR>
  an &Fortran90.&Help<Tab>VimF90\ Help :help vimf90.txt<CR>
endif
