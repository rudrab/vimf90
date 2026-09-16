"########################################################################
" File:          autoload/doc.vim
" Author:        Rudra Banerjee (bnrj DOT rudra at gmail.com)
" License:       GPLv3
" Description:   FORD (Fortran Documenter) integration: Docstrings, Project
"                Documentation Builder (:FordBuild), and Browser Preview (:FordPreview)
"########################################################################

let s:save_cpo = &cpo
set cpo&vim

" Generate Docstring for subprogram, module, derived type, or interface {{{1
function! doc#generate(style) abort
  let l:style = !empty(a:style) ? tolower(a:style) : get(g:, 'fortran_doc_style', 'ford')
  let l:cur_line = line('.')
  let l:max_lines = line('$')

  " Find header start line
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
    echo 'vimf90: Could not parse construct signature.'
    return
  endif

  " Scan body for argument declarations if subprogram
  let l:arg_details = {}
  if l:meta.kind ==# 'subroutine' || l:meta.kind ==# 'function'
    let l:arg_details = s:scan_arguments(l:meta.args, l:header_end + 1, l:max_lines)
  endif

  " Build docstring block
  let l:doc_lines = s:build_docstring(l:meta, l:arg_details, l:indent, l:style)

  " Insert docstring above header
  call append(l:header_start - 1, l:doc_lines)

  " Position cursor on description line
  call cursor(l:header_start, len(l:indent) + 12)
  echomsg 'vimf90: Generated ' . (l:style ==# 'doxygen' ? 'Doxygen' : 'FORD') . ' docstring for ' . l:meta.kind . ' ' . l:meta.name . '.'
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
    if l:line =~? '\v^\s*(pure\s+|elemental\s+|recursive\s+|impure\s+|module\s+)*%(subroutine|function|module|submodule|program|type|interface)\s+'
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

  " Match module / submodule / program / type / interface
  let l:other_match = matchlist(a:header, '\v\c<(module|submodule|program|type|interface)>%(%(,\s*%(public|private|abstract|extends\([^\)]+\)|bind\([^\)]+\)))*\s*::|\s+)\s*(\w+)?')
  if !empty(l:other_match)
    let l:meta.kind = tolower(l:other_match[1])
    let l:meta.name = !empty(l:other_match[2]) ? l:other_match[2] : ''
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

    if l:line =~# '::'
      let l:parts = split(l:line, '::')
      let l:type_part = l:parts[0]
      let l:vars_part = len(l:parts) > 1 ? l:parts[1] : ''

      let l:intent = ''
      let l:imatch = matchlist(l:type_part, '\v\cintent\s*\(\s*(inout|in|out)\s*\)')
      if !empty(l:imatch)
        let l:intent = tolower(l:imatch[1])
      endif

      let l:is_opt = (l:type_part =~? '\v<optional>') ? 1 : 0
      let l:type_clean = trim(substitute(l:type_part, '\v\c,?\s*(intent\s*\([^\)]*\)|optional|allocatable|pointer|target|value)', '', 'g'))

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

  if a:meta.kind ==# 'module'
    call add(l:lines, a:indent . '!> ' . l:tag . 'brief <Summary description of module ' . a:meta.name . '>')
    call add(l:lines, a:indent . '!> ' . l:tag . 'author ' . expand('$USER'))
    call add(l:lines, a:indent . '!> ' . l:tag . 'date ' . strftime('%Y-%m-%d'))
    call add(l:lines, a:indent . '!>')
    call add(l:lines, a:indent . '!> Detailed overview of module functionality.')
    return l:lines
  elseif a:meta.kind ==# 'type'
    call add(l:lines, a:indent . '!> ' . l:tag . 'brief <Derived type ' . a:meta.name . ' description>')
    call add(l:lines, a:indent . '!>')
    call add(l:lines, a:indent . '!> Describes components and type-bound procedures.')
    return l:lines
  elseif a:meta.kind ==# 'interface'
    let l:iname = !empty(a:meta.name) ? a:meta.name : 'interface'
    call add(l:lines, a:indent . '!> ' . l:tag . 'brief <Interface ' . l:iname . ' description>')
    return l:lines
  endif

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
"}}}1

" FORD Project Documentation Builder & Browser Previewer {{{1
function! doc#find_ford_config() abort
  let l:root = project#find_root()
  if empty(l:root)
    let l:root = getcwd()
  endif

  for l:name in ['ford.md', 'project.md', '.ford.toml', 'ford.toml']
    let l:cand = l:root . '/' . l:name
    if filereadable(l:cand)
      return l:cand
    endif
  endfor

  let l:globbed = globpath(l:root, '*.ford', 0, 1)
  if !empty(l:globbed)
    return l:globbed[0]
  endif

  return ''
endfunction

function! doc#create_default_ford_config(root_dir) abort
  let l:pname = fnamemodify(a:root_dir, ':t')
  let l:cfg = a:root_dir . '/ford.md'
  let l:content = [
        \ '---',
        \ 'project: ' . l:pname,
        \ 'summary: Scientific Fortran package documentation',
        \ 'src_dir: ./src',
        \ 'output_dir: ./doc/html',
        \ 'preprocess: true',
        \ 'display: public',
        \ '         protected',
        \ 'graph: true',
        \ '---',
        \ '# ' . l:pname . ' Documentation',
        \ '',
        \ 'Welcome to the ' . l:pname . ' scientific Fortran documentation generated by FORD.',
        \ ]
  call writefile(l:content, l:cfg)
  echomsg 'vimf90: Created default FORD configuration at: ' . l:cfg
  return l:cfg
endfunction

function! doc#ford_build(...) abort
  if !executable('ford')
    echohl WarningMsg
    echo 'vimf90: FORD is not installed. Install with: pipx install ford'
    echohl None
    return 0
  endif

  let l:root = project#find_root()
  if empty(l:root)
    let l:root = getcwd()
  endif

  let l:cfg = doc#find_ford_config()
  if empty(l:cfg)
    let l:cfg = doc#create_default_ford_config(l:root)
  endif

  let l:cmd_list = ['ford', fnamemodify(l:cfg, ':t')]
  let l:efm = '%f:%l: %m,%f:%l:%c: %m'

  echon 'Building FORD documentation in ' . fnamemodify(l:root, ':t') . ' ...'

  let l:orig_dir = getcwd()
  try
    execute 'lcd ' . fnameescape(l:root)

    let l:is_async = makes#get_opt('fortran_async', 1)
    if l:is_async && (has('job') || has('nvim'))
      let l:opts = {
            \ 'title': 'FORD Build (' . fnamemodify(l:root, ':t') . ')',
            \ 'success_msg': 'FORD documentation built successfully.',
            \ 'fail_msg': 'FORD documentation build failed.',
            \ 'efm': l:efm,
            \ }
      " Run async in project root directory
      return s:run_async_ford(l:cmd_list, l:root, l:opts)
    else
      " Synchronous execution
      let l:out = system('ford ' . fnameescape(fnamemodify(l:cfg, ':t')))
      redraw!
      if v:shell_error == 0
        echomsg 'vimf90: FORD documentation built successfully.'
        return 1
      else
        echohl ErrorMsg | echo 'vimf90: FORD build failed: ' . trim(l:out) | echohl None
        return 0
      endif
    endif
  finally
    execute 'lcd ' . fnameescape(l:orig_dir)
  endtry
endfunction

function! s:run_async_ford(cmd_list, dir, opts) abort
  call setqflist([], 'r', {'title': a:opts.title, 'items': []})
  let l:context = {
        \ 'output': [],
        \ 'title': a:opts.title,
        \ 'success_msg': a:opts.success_msg,
        \ 'fail_msg': a:opts.fail_msg,
        \ 'efm': a:opts.efm,
        \ }

  if has('nvim')
    let l:callbacks = {
          \ 'cwd': a:dir,
          \ 'on_stdout': {j, d, e -> makes#on_job_out(l:context, d)},
          \ 'on_stderr': {j, d, e -> makes#on_job_out(l:context, d)},
          \ 'on_exit':   {j, s, e -> makes#on_job_exit(l:context, s)},
          \ }
    call jobstart(a:cmd_list, l:callbacks)
    return 1
  elseif has('job') && has('channel')
    let l:callbacks = {
          \ 'cwd':      a:dir,
          \ 'out_cb':   {c, msg -> makes#on_job_out(l:context, [msg])},
          \ 'err_cb':   {c, msg -> makes#on_job_out(l:context, [msg])},
          \ 'exit_cb':  {j, status -> makes#on_job_exit(l:context, status)},
          \ 'mode':     'nl',
          \ }
    call job_start(a:cmd_list, l:callbacks)
    return 1
  endif
  return 0
endfunction

function! doc#ford_preview() abort
  let l:root = project#find_root()
  if empty(l:root)
    let l:root = getcwd()
  endif

  let l:doc_candidates = [
        \ l:root . '/doc/html/index.html',
        \ l:root . '/html/index.html',
        \ l:root . '/doc/index.html',
        \ ]

  let l:index_html = ''
  for l:cand in l:doc_candidates
    if filereadable(l:cand)
      let l:index_html = l:cand
      break
    endif
  endfor

  if empty(l:index_html)
    echomsg 'vimf90: FORD documentation index not found. Building first...'
    call doc#ford_build()
    " Check again
    for l:cand in l:doc_candidates
      if filereadable(l:cand)
        let l:index_html = l:cand
        break
      endif
    endfor
  endif

  if empty(l:index_html)
    echohl WarningMsg | echo 'vimf90: Could not find generated index.html. Run :FordBuild first.' | echohl None
    return 0
  endif

  echomsg 'vimf90: Opening FORD docs in browser: ' . l:index_html
  if has('unix') && !has('mac')
    call system('xdg-open ' . fnameescape(l:index_html) . ' &')
  elseif has('mac')
    call system('open ' . fnameescape(l:index_html) . ' &')
  elseif has('win32') || has('win64')
    call system('start ' . fnameescape(l:index_html))
  endif
  return 1
endfunction
"}}}1

let &cpo = s:save_cpo
unlet s:save_cpo
