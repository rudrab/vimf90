"########################################################################
" File:          ftplugin/fortran_menu.vim
" Author:        Rudra Banerjee (bnrj DOT rudra at gmail.com)
" Version:       0.7
" License:       GPLv3
" Description:   Guard for the Fortran GUI menu. The menu itself is defined in
"                autoload/fortran_menu.vim so that it can be tested without a
"                running GUI.
"########################################################################

let s:save_cpo = &cpo
set cpo&vim

if !exists('g:Fortran_menumode')
  let g:Fortran_menumode = 1
endif

if has('gui_running') && has('menu') && g:Fortran_menumode == 1
  call fortran_menu#setup()
endif

let &cpo = s:save_cpo
unlet s:save_cpo
