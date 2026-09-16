"########################################################################
" File:          autoload/doc.vim
" Author:        Rudra Banerjee (bnrj DOT rudra at gmail.com)
" License:       GPLv3
" Description:   Automatic FORD and Doxygen docstring generator for Fortran
"                subroutines, functions, modules, and types
"########################################################################

let s:save_cpo = &cpo
set cpo&vim

function! doc#generate(style) abort
  let l:style = !empty(a:style) ? tolower(a:style) : get(g:, 'fortran_doc_style', 'ford')
  let l:cur_line = line('.')
  let l:max_lines = line('$')

  " Find subprogram start line
  let l:header_start = s:find_header_start(l:cur_line)
  if l:header_start == 0
    echo 'vimf90: No Fortran subprogram, module, or type found at or near cursor.'
    return
  endif

  " Read header lines (handling & continuation)
  let [l:full_header, l:header_end] = s:collect_header(l:header_start)
  let l:indent = matchstr(getline(l:header_start), '^\s*')

  " Parse header signature
  let l:meta = s:parse_signature(l:full_header)
  if empty(l:meta)
    echo 'vimf90: Could not parse subprogram signature.'
    return
  endif

  " Scan body for argument declarations (type, intent, optional)
  let l:arg_details = s:scan_arguments(l:meta.args, l:header_end + 1, l:max_lines)

  " Build docstring block
  let l:doc_lines = s:build_docstring(l:meta, l:arg_details, l:indent, l:style)

  " Insert docstring above header
  call append(l:header_start - 1, l:doc_lines)

  " Position cursor on description line
  call cursor(l:header_start, len(l:indent) + 12)
  echo 'vimf90: Generated ' . (l:style ==# 'doxygen' ? 'Doxygen' : 'FORD') . ' docstring for ' . l:meta.name . '.'
endfunction

function! s:find_header_start(start_lnum) abort
  let l:lnum = a:start_lnum
  while l:lnum >= 1 && l:lnum >= a:start_lnum - 100
    let l:line = getline(l:lnum)
    " Ignore comments
    if l:line =~# '^\s*!'
      let l:lnum -= 1
      continue
    endif
    if l:line =~? '\v^\s*(pure\s+|elemental\s+|recursive\s+|impure\s+|module\s+)*%(subroutine|function|module|submodule|program|type)\s+'
      return l:lnum
    endif
    let l:lnum -= 1
  endwhile
  return 0
endfunction

function! s:collect_header(start_lnum) abort
  let l:lnum = a:start_lnum
  let l:full = ''
  while l:lnum <= line('$')
    let l:line = getline(l:lnum)
    " Strip trailing comment
    let l:clean = substitute(l:line, '!.*$', '', '')
    let l:clean = substitute(l:clean, '^\s*', '', '')
    let l:clean = substitute(l:clean, '\s*$', '', '')

    if l:clean =~# '&$'
      let l:full .= ' ' . substitute(l:clean, '&$', '', '')
      let l:lnum += 1
    else
      let l:full .= ' ' . l:clean
      break
    endif
  endwhile
  return [trim(l:full), l:lnum]
endfunction

function! s:parse_signature(header) abort
  let l:meta = { 'kind': '', 'name': '', 'args': [], 'result': '' }

  " Match subroutine
  let l:sub_match = matchlist(a:header, '\v\c<subroutine>\s+(\w+)\s*(\([^\)]*\))?')
  if !empty(l:sub_match)
    let l:meta.kind = 'subroutine'
    let l:meta.name = l:sub_match[1]
    let l:arg_str = l:sub_match[2]
    let l:meta.args = s:extract_args(l:arg_str)
    return l:meta
  endif

  " Match function
  let l:fn_match = matchlist(a:header, '\v\c<function>\s+(\w+)\s*(\([^\)]*\))?\s*(result\s*\(\s*(\w+)\s*\))?')
  if !empty(l:fn_match)
    let l:meta.kind = 'function'
    let l:meta.name = l:fn_match[1]
    let l:arg_str = l:fn_match[2]
    let l:meta.args = s:extract_args(l:arg_str)
    let l:meta.result = !empty(l:fn_match[4]) ? l:fn_match[4] : l:fn_match[1]
    return l:meta
  endif

  " Match module / submodule / program / type
  let l:other_match = matchlist(a:header, '\v\c<(module|submodule|program|type)>%(%(,\s*%(public|private|abstract|extends\([^\)]+\)|bind\([^\)]+\)))*\s*::|\s+)\s*(\w+)')
  if !empty(l:other_match)
    let l:meta.kind = tolower(l:other_match[1])
    let l:meta.name = l:other_match[2]
    return l:meta
  endif

  return {}
endfunction

function! s:extract_args(arg_str) abort
  if empty(a:arg_str)
    return []
  endif
  let l:clean = substitute(a:arg_str, '^[() ]\+', '', '')
  let l:clean = substitute(l:clean, '[() ]\+$', '', '')
  let l:tokens = split(l:clean, '\s*,\s*')
  return filter(l:tokens, '!empty(v:val)')
endfunction

function! s:scan_arguments(args, start_line, max_lines) abort
  let l:details = {}
  for l:a in a:args
    let l:details[tolower(l:a)] = { 'name': l:a, 'intent': '', 'optional': 0, 'type': '' }
  endfor

  let l:lnum = a:start_line
  let l:scan_limit = min([a:max_lines, a:start_line + 60])

  while l:lnum <= l:scan_limit
    let l:line = getline(l:lnum)
    if l:line =~? '\v^\s*(contains|end\s+(subroutine|function|module|program))'
      break
    endif

    " Check declaration line with ::
    if l:line =~# '::'
      let l:parts = split(l:line, '::')
      let l:type_part = l:parts[0]
      let l:vars_part = len(l:parts) > 1 ? l:parts[1] : ''

      " Extract intent
      let l:intent = ''
      let l:imatch = matchlist(l:type_part, '\v\cintent\s*\(\s*(inout|in|out)\s*\)')
      if !empty(l:imatch)
        let l:intent = tolower(l:imatch[1])
      endif

      let l:is_opt = (l:type_part =~? '\v<optional>') ? 1 : 0

      " Clean type
      let l:type_clean = trim(substitute(l:type_part, '\v\c,?\s*(intent\s*\([^\)]*\)|optional|allocatable|pointer|target|value)', '', 'g'))

      " Check if any dummy arguments are in vars_part
      for l:a in a:args
        let l:key = tolower(l:a)
        if has_key(l:details, l:key)
          if l:vars_part =~? '\v<' . l:a . '>'
            if !empty(l:intent)
              let l:details[l:key].intent = l:intent
            endif
            if l:is_opt
              let l:details[l:key].optional = 1
            endif
            if !empty(l:type_clean)
              let l:details[l:key].type = l:type_clean
            endif
          endif
        endif
      endfor
    endif
    let l:lnum += 1
  endwhile

  return l:details
endfunction

function! s:build_docstring(meta, arg_details, indent, style) abort
  let l:tag = (a:style ==# 'doxygen') ? '\' : '@'
  let l:lines = []

  call add(l:lines, a:indent . '!> ' . l:tag . 'brief <Brief description of ' . a:meta.name . '>')
  call add(l:lines, a:indent . '!>')

  if !empty(a:meta.args)
    for l:a in a:meta.args
      let l:key = tolower(l:a)
      let l:info = get(a:arg_details, l:key, { 'name': l:a, 'intent': '', 'optional': 0, 'type': '' })
      
      let l:intent_str = ''
      if !empty(l:info.intent)
        let l:intent_str = '[' . l:info.intent . (l:info.optional ? ',optional' : '') . ']'
      elseif l:info.optional
        let l:intent_str = '[optional]'
      endif

      let l:line = a:indent . '!> ' . l:tag . 'param' . l:intent_str . ' ' . l:a
      if !empty(l:info.type)
        let l:line .= ' ' . l:info.type . ' description.'
      else
        let l:line .= ' Description.'
      endif
      call add(l:lines, l:line)
    endfor
  endif

  if a:meta.kind ==# 'function' && !empty(a:meta.result)
    call add(l:lines, a:indent . '!> ' . l:tag . 'return Return value (' . a:meta.result . ').')
  endif

  return l:lines
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
