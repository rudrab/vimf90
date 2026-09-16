"########################################################################
" File:          autoload/tagbar.vim
" Author:        Rudra Banerjee (bnrj DOT rudra at gmail.com)
" License:       GPLv3
" Description:   Tagbar and symbol outline configuration for modern Fortran
"########################################################################

let s:save_cpo = &cpo
set cpo&vim

function! tagbar#setup() abort
  if !exists('g:tagbar_type_fortran')
    let g:tagbar_type_fortran = {
          \ 'ctagstype': 'fortran',
          \ 'kinds': [
          \   'p:programs:0:0',
          \   'm:modules:0:0',
          \   's:submodules:0:0',
          \   't:derived_types:0:0',
          \   'i:interfaces:0:0',
          \   'b:block_data:0:0',
          \   'c:constants:1:0',
          \   'v:variables:1:0',
          \   'f:functions:0:0',
          \   'r:subroutines:0:0',
          \   'e:enumerations:0:0',
          \   'N:namelists:0:0'
          \ ],
          \ 'sro': '%',
          \ 'kind2scope': {
          \   'm': 'module',
          \   's': 'submodule',
          \   't': 'type',
          \   'p': 'program',
          \   'i': 'interface'
          \ },
          \ 'scope2kind': {
          \   'module': 'm',
          \   'submodule': 's',
          \   'type': 't',
          \   'program': 'p',
          \   'interface': 'i'
          \ }
          \ }
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
