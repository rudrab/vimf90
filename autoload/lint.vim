"########################################################################
" File:          autoload/lint.vim
" Author:        Rudra Banerjee (bnrj DOT rudra at gmail.com)
" License:       GPLv3
" Description:   Fortran linting through fortitude (:FortranLint)
"
" fortls reports what the compiler would, and fprettify fixes layout. Neither
" says that `integer*4` is non-standard or that a module is missing `implicit
" none (external)`. fortitude does, so it fills the one gap in the toolchain.
"########################################################################

let s:save_cpo = &cpo
set cpo&vim

" fortitude's concise output is file:line:col: CODE message. Everything after
" the findings -- the file count, the totals, the hint about `explain` -- is
" summary text, dropped by the final catch-all.
let s:efm = '%f:%l:%c: %m,%-G%.%#'

function! s:executable() abort
  return get(g:, 'fortran_fortitude_command', 'fortitude')
endfunction

function! s:missing() abort
  echohl WarningMsg
  echo 'vimf90: fortitude is not installed. Install with: pip install --user fortitude-lint'
  echohl None
  return 0
endfunction

" How the run went. A linter that finds something has not failed, so this
" reports a count rather than the build runner's success or failure message.
function! s:report(status) abort
  let l:items = filter(getqflist(), 'v:val.valid')
  redraw!

  " fortitude exits 1 when it has findings and 2 or more when it could not
  " run at all; without findings, a non-zero exit is the latter.
  if empty(l:items)
    if a:status > 1
      echohl ErrorMsg
      echo 'vimf90: fortitude failed (exit code ' . a:status . ').'
      echohl None
      botright cwindow
    else
      echomsg 'vimf90: fortitude found no issues.'
      if get(g:, 'fortran_qf_auto_close', 1)
        cclose
      endif
    endif
    return
  endif

  echomsg printf('vimf90: fortitude found %d issue%s.', len(l:items), len(l:items) == 1 ? '' : 's')
  botright cwindow
endfunction

" Lint the current file, or the whole project when bang is '!'.
function! lint#run(...) abort
  let l:bang = a:0 > 0 && a:1 ==# '!'
  if !executable(s:executable())
    return s:missing()
  endif

  if l:bang
    let l:root = project#find_root()
    if empty(l:root) || !isdirectory(l:root)
      let l:root = getcwd()
    endif
    let l:target = l:root
    let l:title = 'fortitude (' . fnamemodify(l:root, ':t') . ')'
  else
    if empty(expand('%'))
      echohl WarningMsg | echo 'vimf90: no file to lint.' | echohl None
      return 0
    endif
    silent update
    let l:target = expand('%:p')
    let l:title = 'fortitude (' . expand('%:t') . ')'
  endif

  let l:cmd = [s:executable(), 'check', '--output-format', 'concise']
        \ + split(get(g:, 'fortran_fortitude_args', '')) + [l:target]

  let l:opts = {
        \ 'title': l:title,
        \ 'efm': s:efm,
        \ 'report': function('s:report'),
        \ }

  echon 'Linting ' . fnamemodify(l:target, ':t') . ' ...'
  if makes#get_opt('fortran_async', 1) && makes#run_job(l:cmd, l:opts)
    return 1
  endif

  " Synchronous fallback, for an editor without job support.
  let l:out = systemlist(join(map(copy(l:cmd), 'shellescape(v:val)'), ' '))
  let l:status = v:shell_error
  let l:saved = &errorformat
  try
    let &errorformat = s:efm
    call setqflist([], 'r', {'title': l:title, 'lines': l:out})
  finally
    let &errorformat = l:saved
  endtry
  call s:report(l:status)
  return 1
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
