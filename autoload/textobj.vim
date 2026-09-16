"########################################################################
" File:          autoload/textobj.vim
" Author:        Rudra Banerjee (bnrj DOT rudra at gmail.com)
" License:       GPLv3
" Description:   Fortran Text Objects (subroutines, functions, modules,
"                derived types, loops, blocks) and Structural Motions
"########################################################################

let s:save_cpo = &cpo
set cpo&vim

" Regex patterns for Fortran constructs
let s:re_prefix = '\v^\s*(pure\s+|elemental\s+|recursive\s+|impure\s+|module\s+)*'

let s:patterns = {
      \ 'func': {
      \   'start': '\v\c^\s*(pure\s+|elemental\s+|recursive\s+|impure\s+|module\s+)*%(subroutine|function)\s+\w+',
      \   'end':   '\v\c^\s*end\s*%(subroutine|function)>'
      \ },
      \ 'module': {
      \   'start': '\v\c^\s*%(module\s+(procedure|subroutine|function|nature)@!\w+|submodule\s*\(|program\s+\w+)',
      \   'end':   '\v\c^\s*end\s*%(module|submodule|program)>'
      \ },
      \ 'type': {
      \   'start': '\v\c^\s*type%(%(,\s*%(public|private|abstract|extends\([^\)]+\)|bind\([^\)]+\)))*\s*::|\s+)\s*\w+',
      \   'end':   '\v\c^\s*end\s*type>'
      \ },
      \ 'do': {
      \   'start': '\v\c^\s*(%(\w+\s*:\s*)?do(\s+.*|\s*$))',
      \   'end':   '\v\c^\s*end\s*do>'
      \ },
      \ 'block': {
      \   'start': '\v\c^\s*(%(\w+\s*:\s*)?block|interface)\s*($|[^a-zA-Z0-9_])',
      \   'end':   '\v\c^\s*end\s*%(block|interface)>'
      \ }
      \ }

" Find boundary lines of the enclosing construct
function! textobj#find_bounds(type) abort
  if !has_key(s:patterns, a:type)
    return [0, 0]
  endif

  let l:p = s:patterns[a:type]
  let l:cur_line = line('.')
  let l:cur_col  = col('.')

  " Save view
  let l:view = winsaveview()

  let l:start_line = 0
  let l:end_line = 0

  " Search backward for start of construct
  " If current line itself matches start pattern, search backwards with 'c' flag
  let l:flags = 'bWc'
  let l:depth = 1

  " Look backward for start
  let l:sline = search(l:p.start, l:flags)
  while l:sline > 0
    " Find corresponding end by moving forward from start
    let l:save_s = winsaveview()
    let l:eline = s:find_matching_end(l:p.start, l:p.end, l:sline)
    if l:eline >= l:cur_line
      " Found an enclosing construct!
      let l:start_line = l:sline
      let l:end_line = l:eline
      break
    endif
    " If this construct ended before cur_line, look further back
    call winrestview(l:save_s)
    let l:sline = search(l:p.start, 'bW')
  endwhile

  call winrestview(l:view)
  return [l:start_line, l:end_line]
endfunction

function! s:find_matching_end(pat_start, pat_end, start_line) abort
  let l:cur = a:start_line
  let l:max_lines = line('$')
  let l:depth = 1

  call cursor(a:start_line, 1)

  while l:depth > 0
    let l:next_match = search('\v\c(' . a:pat_start . '|' . a:pat_end . ')', 'W')
    if l:next_match == 0 || l:next_match > l:max_lines
      return 0
    endif

    let l:line_str = getline(l:next_match)
    " Ignore comments
    if l:line_str =~# '^\s*!'
      continue
    endif

    if l:line_str =~? a:pat_start
      let l:depth += 1
    elseif l:line_str =~? a:pat_end
      let l:depth -= 1
    endif
  endwhile

  return line('.')
endfunction

" Select text object
function! textobj#select(type, inner) abort
  let [l:start, l:end] = textobj#find_bounds(a:type)
  if l:start == 0 || l:end == 0
    return
  endif

  if a:inner
    " Inside: select from start+1 to end-1
    let l:sel_start = l:start + 1
    let l:sel_end = l:end - 1
    if l:sel_start > l:sel_end
      " Empty body
      let l:sel_start = l:start
      let l:sel_end = l:start
    endif
  else
    " Around: full construct
    let l:sel_start = l:start
    let l:sel_end = l:end
  endif

  " Select lines linewise
  call cursor(l:sel_start, 1)
  normal! V
  call cursor(l:sel_end, len(getline(l:sel_end)))
endfunction

" Motion jumps
function! textobj#jump(pat_type, forward, to_end) abort
  let l:flags = (a:forward ? '' : 'b') . 'W'
  let l:pat = ''

  if a:pat_type ==# 'subprog'
    if a:to_end
      let l:pat = '\v\c^\s*end\s*%(subroutine|function|program|module|submodule)>'
    else
      let l:pat = '\v\c^\s*(pure\s+|elemental\s+|recursive\s+|impure\s+|module\s+)*%(subroutine|function|program|module\s+(procedure|subroutine|function|nature)@!\w+|submodule\s*\()'
    endif
  endif

  if !empty(l:pat)
    call search(l:pat, l:flags)
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
