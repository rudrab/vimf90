"########################################################################
" File:          ftplugin/fortran_state.vim
" Author:        Rudra Banerjee (bnrj DOT rudra at gmail.com)
" Version:       0.4
" License:       GPLv3
" Description:   Fortran buffer formatting via fprettify
"########################################################################

let s:save_cpo = &cpo
set cpo&vim

" Formatting via fprettify
function! s:format_fprettify() abort
  if !executable('fprettify')
    echohl WarningMsg | echo 'vimf90: fprettify is not installed or not in PATH (install via: pipx install fprettify)' | echohl None
    return 0
  endif
  if &readonly || !&modifiable
    return 0
  endif

  let l:view = winsaveview()
  let l:opt = get(b:, 'fprettify_options', get(g:, 'fprettify_options', '--silent'))
  execute 'silent %!fprettify ' . l:opt
  if v:shell_error != 0
    silent undo
    echohl ErrorMsg | echo 'vimf90: fprettify formatting failed.' | echohl None
    call winrestview(l:view)
    return 0
  endif
  call winrestview(l:view)
  return 1
endfunction

function! s:format_buffer() abort
  call s:format_fprettify()
endfunction

" Auto format on save if enabled (default off, opt-in)
if get(g:, 'fortran_format_on_save', get(g:, 'fortran_linter', 0) == 2 ? 1 : 0)
  augroup vimf90_format
    autocmd! * <buffer>
    autocmd BufWritePre <buffer> call s:format_fprettify()
  augroup END
endif

" Commands and Plug mappings
command! -buffer -bar FortranFormat call s:format_buffer()
nnoremap <buffer> <silent> <Plug>(vimf90-format) :call <SID>format_buffer()<CR>
command! -buffer -bar FortranInstallDeps call install_deps#check_deps(1)

" Undo ftplugin
let s:undo = 'delcommand FortranFormat | delcommand FortranInstallDeps | unlet! b:fortran_linter b:fprettify_options'
let s:undo .= ' | silent! augroup vimf90_format | silent! autocmd! * <buffer> | silent! augroup END'
let s:undo .= ' | silent! nunmap <buffer> <Plug>(vimf90-format)'
let b:undo_ftplugin = (exists('b:undo_ftplugin') ? b:undo_ftplugin . ' | ' : '') . s:undo

let &cpo = s:save_cpo
unlet s:save_cpo
