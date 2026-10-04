"########################################################################
" File:          autoload/textobj.vim
" Author:        Rudra Banerjee (bnrj DOT rudra at gmail.com)
" License:       GPLv3
" Description:   Fortran Text Objects (subroutines, functions, modules,
"                derived types, loops, blocks) and Structural Motions
"########################################################################

let s:save_cpo = &cpo
set cpo&vim

" Regex patterns for Fortran constructs (very magic, case-insensitive)

" A function statement may be prefixed by a declaration type spec as well as by
" the pure/elemental/recursive/impure/module modifiers, in any order:
"   real function square(x)
"   integer(kind=8) pure function count_it()
"   character(len=*) function label()
"   type(solver) function make_solver()
" The parenthesised part is matched greedily and backtracks, so nested
" parentheses such as real(kind(1.0d0)) are handled.
let s:re_typespec = '%(%(type|class)\s*\(.*\)\s*'
      \ . '|%(integer|real|complex|logical|character)%(\s*\(.*\)\s*|\s*\*\s*\d+\s*|\s+)'
      \ . '|double\s+%(precision|complex)\s+)'
let s:re_modifier = '%(pure|elemental|impure|recursive|non_recursive|module)\s+'
let s:re_prefix   = '%(' . s:re_modifier . '|' . s:re_typespec . ')*'

let s:patterns = {
      \ 'func': {
      \   'start': '\v\c^\s*' . s:re_prefix . '%(subroutine|function)\s+\w+',
      \   'end':   '\v\c^\s*end\s*%(subroutine|function)>'
      \ },
      \ 'module': {
      \   'start': '\v\c^\s*%(module\s+%(%(procedure|subroutine|function|nature)>)@!\w+|submodule\s*\(|program\s+\w+)',
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

" ---------------------------------------------------------------------------
" Fixed source form (FORTRAN 77 and fixed-form Fortran 90+)
"
" Three things differ from free form and none of them are cosmetic:
"   * a statement may carry a label in columns 1-5, so no construct starts at
"     the beginning of the line;
"   * a program unit is terminated by a bare END, with the keyword that says
"     what is ending being optional;
"   * DO loops are usually terminated by a labelled statement rather than by
"     END DO, so the terminator has to be found by matching that label.
" Comments are marked by C, c or * in column one, and a non-blank in column
" six continues the previous statement rather than starting a new one.
" ---------------------------------------------------------------------------

" Optional statement label, then the statement itself.
let s:fx_label = '^\s*%(\d+\s+)?'

" END, ENDDO, END SUBROUTINE FOO: the keyword and the name are both optional,
" so the whole statement has to be anchored to avoid swallowing END IF.
let s:fx_unit_end = s:fx_label
      \ . 'end%(\s*%(subroutine|function|program|module|submodule|blockdata|block\s+data)%(\s+\w+)?)?\s*$'

let s:fixed_patterns = {
      \ 'func': {
      \   'start': '\v\c' . s:fx_label . s:re_prefix
      \            . '%(subroutine|function)\s+\w+|\v\c' . s:fx_label . 'block\s*data>',
      \   'end':   '\v\c' . s:fx_unit_end
      \ },
      \ 'module': {
      \   'start': '\v\c' . s:fx_label
      \            . '%(module\s+%(%(procedure|subroutine|function|nature)>)@!\w+|submodule\s*\(|program\s+\w+)',
      \   'end':   '\v\c' . s:fx_unit_end
      \ },
      \ 'type': {
      \   'start': '\v\c' . s:fx_label . 'type%(%(,\s*%(public|private|abstract))*\s*::|\s+)\s*\w+',
      \   'end':   '\v\c' . s:fx_label . 'end\s*type>'
      \ },
      \ 'do': {
      \   'start': '\v\c' . s:fx_label . '%(\w+\s*:\s*)?do>',
      \   'end':   '\v\c' . s:fx_label . 'end\s*do>'
      \ },
      \ 'block': {
      \   'start': '\v\c' . s:fx_label . '%(%(\w+\s*:\s*)?block>|interface>)',
      \   'end':   '\v\c' . s:fx_label . 'end\s*%(block|interface)>'
      \ }
      \ }

" Fixed source form, decided the way Vim's own fortran ftplugin decides it:
" buffer-local setting first, then the global one, then the file extension.
" b:fortran_fixed_source is what the bundled ftplugin leaves behind, including
" its content sniffing for ambiguous extensions, so prefer it when present.
function! textobj#is_fixed_form() abort
  if exists('b:fortran_fixed_source')
    return b:fortran_fixed_source ? 1 : 0
  elseif exists('g:fortran_free_source')
    return 0
  elseif exists('g:fortran_fixed_source')
    return 1
  endif
  return expand('%:e') =~? '^\%(f\|f77\|for\|ftn\)$' ? 1 : 0
endfunction

function! s:patterns() abort
  return textobj#is_fixed_form() ? s:fixed_patterns : s:patterns
endfunction

" A comment line. In fixed form the marker must sit in column one; an inline !
" comment is a widespread extension and is accepted in both forms.
function! s:is_comment(line) abort
  return textobj#is_fixed_form() ? a:line =~# '^[cC*!]' : a:line =~# '^\s*!'
endfunction

" A continuation line carries a non-blank, non-zero character in column six and
" nothing but blanks or a label before it. It continues the previous statement,
" so it can never open or close a construct.
function! s:is_continuation(line) abort
  if !textobj#is_fixed_form() || strlen(a:line) < 6
    return 0
  endif
  return a:line[0:4] =~# '^[ 0-9]*$' && a:line[5] !~# '[ 0]'
endfunction

" A labelled DO ends at the statement carrying its label, which is conventionally
" CONTINUE but is allowed to be any executable statement.
function! s:find_labelled_do_end(start_line) abort
  let l:label = matchstr(getline(a:start_line), '\c^\s*\%(\d\+\s\+\)\?do\s\+\zs\d\+')
  if empty(l:label)
    return -1
  endif
  let l:n = a:start_line + 1
  while l:n <= line('$')
    let l:text = getline(l:n)
    if !s:is_comment(l:text) && !s:is_continuation(l:text)
          \ && matchstr(l:text, '^\s*\zs\d\+') ==# l:label
      return l:n
    endif
    let l:n += 1
  endwhile
  return 0
endfunction

" Find boundary lines of the enclosing construct
function! textobj#find_bounds(type) abort
  let l:patterns = s:patterns()
  if !has_key(l:patterns, a:type)
    return [0, 0]
  endif

  let l:p = l:patterns[a:type]
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
    let l:eline = s:find_end(l:p, a:type, l:sline)
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

" Where the construct opened at start_line ends.
"
" In fixed form a DO loop is normally closed by a labelled statement rather
" than by END DO, so that case is resolved by matching the label and never
" reaches the depth counter. Everything else counts openings against closings
" as usual.
function! s:find_end(pattern, type, start_line) abort
  if a:type ==# 'do' && textobj#is_fixed_form()
    let l:labelled = s:find_labelled_do_end(a:start_line)
    if l:labelled >= 0
      return l:labelled
    endif
  endif
  return s:find_matching_end(a:pattern.start, a:pattern.end, a:start_line)
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
    " Ignore comments and continuation lines: neither can open or close a
    " construct, and in fixed form a continuation may well look like one.
    if s:is_comment(l:line_str) || s:is_continuation(l:line_str)
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
    if textobj#is_fixed_form()
      " A bare END closes a program unit in fixed form, and a statement may
      " carry a label, so neither end of the motion can assume column one.
      let l:pat = a:to_end
            \ ? '\v\c' . s:fx_unit_end
            \ : '\v\c' . s:fx_label . s:re_prefix
            \   . '%(subroutine|function|program|module\s+%(%(procedure|subroutine|function|nature)>)@!\w+'
            \   . '|submodule\s*\(|block\s*data>)'
    elseif a:to_end
      let l:pat = '\v\c^\s*end\s*%(subroutine|function|program|module|submodule)>'
    else
      let l:pat = '\v\c^\s*' . s:re_prefix . '%(subroutine|function|program|module\s+%(%(procedure|subroutine|function|nature)>)@!\w+|submodule\s*\()'
    endif
  endif

  if !empty(l:pat)
    call search(l:pat, l:flags)
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
