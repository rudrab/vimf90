"########################################################################
" File:          autoload/install_deps.vim
" Author:        Rudra Banerjee (bnrj DOT rudra at gmail.com)
" Version:       0.3
" License:       GPLv3
" Description:   Install Fortran python dependencies (fprettify, fortls, etc.)
"########################################################################

function! install_deps#install_fprettify() abort
  echomsg 'Installing fprettify...'
  execute '!pip3 install fprettify --user'
endfunction

function! install_deps#install_unidecode() abort
  echomsg 'Installing unidecode...'
  execute '!pip3 install unidecode --user'
endfunction

function! install_deps#install_fortls() abort
  echomsg 'Installing fortls (fortran-language-server)...'
  execute '!pip3 install fortran-language-server --user'
endfunction

function! install_deps#install_all() abort
  echomsg 'Installing all recommended Python dependencies for vimf90...'
  execute '!pip3 install fprettify fortran-language-server unidecode --user'
  redraw!
  echomsg 'vimf90 dependencies installed.'
endfunction

function! install_deps#check_deps() abort
  let l:missing = []
  if !executable('fprettify')
    call add(l:missing, 'fprettify')
  endif
  if !executable('fortls')
    call add(l:missing, 'fortran-language-server (fortls)')
  endif
  if empty(l:missing)
    echomsg 'All vimf90 Python dependencies are installed.'
    return 1
  else
    echohl WarningMsg
    echomsg 'Missing vimf90 Python dependencies: ' . join(l:missing, ', ')
    echomsg 'Run :FortranInstallDeps to install them.'
    echohl None
    return 0
  endif
endfunction
