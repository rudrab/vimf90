"########################################################################
" File:          autoload/install_deps.vim
" Author:        Rudra Banerjee (bnrj DOT rudra at gmail.com)
" Version:       0.4
" License:       GPLv3
" Description:   Check and optionally install Fortran companion tools (fprettify, fortls)
"########################################################################

let s:save_cpo = &cpo
set cpo&vim

function! install_deps#check_deps(...) abort
  let l:missing = []
  if !executable('fprettify')
    call add(l:missing, 'fprettify')
  endif
  if !executable('fortls')
    call add(l:missing, 'fortls')
  endif

  if empty(l:missing)
    echo 'vimf90: All recommended tools (fprettify, fortls) are installed and available.'
    return 1
  endif

  let l:install_opt = a:0 > 0 ? a:1 : 0
  let l:miss_str = join(l:missing, ', ')

  if l:install_opt == 0
    " Default: concise one-line advisory
    echohl WarningMsg
    echo 'vimf90: Optional tools missing: ' . l:miss_str . '. Install with: pipx install ' . join(l:missing, ' ') . ' (or :FortranInstallDeps install)'
    echohl None
    return 0
  endif

  " User requested or called :FortranInstallDeps
  let l:choice = confirm('Install missing tools (' . l:miss_str . ') via pip user install?', "&Yes\n&No", 2)
  if l:choice == 1
    echomsg 'vimf90: Running pip install for ' . l:miss_str . '...'
    let l:cmd = 'pip3 install --user ' . join(l:missing, ' ')
    let l:out = system(l:cmd)
    redraw!
    if v:shell_error == 0
      echomsg 'vimf90: Successfully installed ' . l:miss_str . '.'
      return 1
    else
      echohl ErrorMsg | echo 'vimf90: Installation failed. Please install manually using: pipx install ' . join(l:missing, ' ') | echohl None
      return 0
    endif
  else
    echo 'vimf90: To install manually later, run: pipx install ' . join(l:missing, ' ')
    return 0
  endif
endfunction

function! install_deps#run(arg) abort
  if a:arg =~? 'install\|force'
    let l:missing = ['fprettify', 'fortls']
    let l:cmd = 'pip3 install --user ' . join(l:missing, ' ')
    echomsg 'vimf90: Running pip install...'
    let l:out = system(l:cmd)
    redraw!
    if v:shell_error == 0
      echomsg 'vimf90: Successfully installed dependencies.'
    else
      echohl ErrorMsg | echo 'vimf90: Installation failed: ' . trim(l:out) | echohl None
    endif
  else
    call install_deps#check_deps(1)
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
