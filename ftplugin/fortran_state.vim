"########################################################################
" File:          ftplugin/fortran_state.vim
" Author:        Rudra Banerjee (bnrj DOT rudra at gmail.com)
" Version:       0.3
" License:       GPLv3
" Description:   Fortran statement completion, linting, and formatting
"########################################################################

" User configuration
let b:fortran_linter     = get(g:, 'fortran_linter', 1)
let b:fprettify_options  = get(g:, 'fprettify_options', '--silent')
let b:fortran_leader     = get(g:, 'fortran_leader', get(g:, 'mapleader', '\'))

" Formatting functions {{{1
function! s:format_regex() abort
  if &readonly || !&modifiable
    return
  endif
  let l:view = winsaveview()
  let l:search = @/

  " Whitespace normalization
  silent! keeppatterns %s/\v(\w) ?(\+|\-|\/|\*|\*\*) ?(\w|-)/\1\2\3/ge
  silent! keeppatterns %s/\v(\w) ?(\>\=|\<\=|\/\=|\=|\=\=|\>|\<) ?(\w|-)/\1 \2 \3/ge
  silent! keeppatterns %s/\v(\w) ?(\c\.eq\.|\c\.ne\.|\c\.gt\.|\c\.lt\.|\c\.ge\.|\c\.le\.) ?(\w|-)/\1 \2 \3/ge
  silent! keeppatterns %s/\v(\w) ?(\c\.and\.|\c\.not\.|\c\.or\.|\c\.eqv\.|\c\.neqv\.) ?(\w|-)/\1 \2 \3/ge
  silent! keeppatterns %s/\v(\w|\)) ?(\,|\;) ?/\1\2 \3/ge
  silent! keeppatterns %s/\v(\w|\)) ?(\:\:) ?(\w|-)/\1\2 \3/ge
  silent! keeppatterns %s/\v(\w|\)) ?(!) ?(\w|-)/\1  \2 \3/ge

  let @/ = l:search
  call winrestview(l:view)
endfunction

function! s:format_fprettify() abort
  if !executable('fprettify')
    echohl WarningMsg | echo 'fprettify is not installed or not in PATH.' | echohl None
    return
  endif
  if &readonly || !&modifiable
    return
  endif

  let l:view = winsaveview()
  let l:opt = get(b:, 'fprettify_options', get(g:, 'fprettify_options', '--silent'))
  execute 'silent %!fprettify ' . l:opt
  if v:shell_error != 0
    silent undo
    echohl ErrorMsg | echo 'fprettify formatting failed.' | echohl None
  endif
  call winrestview(l:view)
endfunction

function! s:format_buffer() abort
  let l:mode = get(b:, 'fortran_linter', get(g:, 'fortran_linter', 1))
  if l:mode == 1
    call s:format_regex()
  elseif l:mode == 2
    call s:format_fprettify()
  endif
endfunction
"}}}1

" Linting and formatting triggers {{{1
if b:fortran_linter == 0
  " On-the-fly insert mode adjustments
  inoremap <buffer> <expr> = stridx('</=>', getline('.')[col('.')-3]) >= 0 ? '<bs>= ' : getline('.')[col('.')-2] =~ '\s' ? '= ' : '='
  inoremap <buffer> <expr> > stridx('</=>', getline('.')[col('.')-3]) >= 0 ? '<bs>> ' : getline('.')[col('.')-2] =~ '\s' ? '> ' : '>'
  inoremap <buffer> <expr> + getline('.')[col('.')-2] =~ '\s' ? '+ ' : '+'
  inoremap <buffer> <expr> - getline('.')[col('.')-2] =~ '\s' ? '- ' : '-'
  inoremap <buffer> <expr> * getline('.')[col('.')-2] =~ '\s' ? '* ' : '*'
  inoremap <buffer> <expr> / getline('.')[col('.')-2] =~ '\s' ? '/ ' : '/'
elseif b:fortran_linter == 1
  augroup vimf90_format
    autocmd! * <buffer>
    autocmd BufWritePre <buffer> call s:format_regex()
  augroup END
elseif b:fortran_linter == 2
  augroup vimf90_format
    autocmd! * <buffer>
    autocmd BufWritePre <buffer> call s:format_fprettify()
  augroup END
endif
"}}}1

" Commands and Plug mappings
command! -buffer -bar FortranFormat call s:format_buffer()
nnoremap <buffer> <silent> <Plug>(vimf90-format) :call <SID>format_buffer()<CR>
command! -buffer -bar FortranInstallDeps call install_deps#install_all()

" Undo ftplugin
let s:undo = 'delcommand FortranFormat | delcommand FortranInstallDeps | unlet! b:fortran_linter b:fprettify_options b:fortran_leader | silent! augroup vimf90_format | silent! autocmd! * <buffer> | silent! augroup END | silent! nunmap <buffer> <Plug>(vimf90-format)'
let b:undo_ftplugin = (exists('b:undo_ftplugin') ? b:undo_ftplugin . ' | ' : '') . s:undo
