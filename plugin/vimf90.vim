"########################################################################
" File:          plugin/vimf90.vim
" Author:        Rudra Banerjee (bnrj DOT rudra at gmail.com)
" License:       GPLv3
" Description:   Global setup for vimf90. Only things that must exist before,
"                or independently of, a Fortran buffer belong here; everything
"                buffer-local lives in ftplugin/.
"########################################################################

if exists('g:loaded_vimf90')
  finish
endif
let g:loaded_vimf90 = 1

let s:save_cpo = &cpo
set cpo&vim

" Keep .fortls in step with the project manifest. This has to be global: a
" manifest is usually edited on its own, in a session where no Fortran buffer
" has been opened, so an ftplugin would never have been sourced to register it.
if get(g:, 'fortran_fortls_autoconfig', 1)
  augroup vimf90_fpm_manifest
    autocmd!
    autocmd BufWritePost fpm.toml call fortls#generate(expand('<afile>:p:h'))
  augroup END
endif

let &cpo = s:save_cpo
unlet s:save_cpo
