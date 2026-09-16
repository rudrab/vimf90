"########################################################################
" File:          autoload/fortls.vim
" Author:        Rudra Banerjee (bnrj DOT rudra at gmail.com)
" License:       GPLv3
" Description:   Automated .fortls LSP configuration generator for fpm projects
"########################################################################

let s:save_cpo = &cpo
set cpo&vim

" Discover all directories containing Fortran source files under a base dir {{{1
function! s:find_source_subdirs(root, rel_base) abort
  let l:abs_base = a:root . '/' . a:rel_base
  if !isdirectory(l:abs_base)
    return []
  endif

  let l:fortran_exts = ['f90', 'f95', 'f03', 'f08', 'F90', 'F95', 'f', 'F', 'for', 'FOR', 'f77', 'F77']
  let l:patterns = map(copy(l:fortran_exts), 'l:abs_base . "/**/*." . v:val') + map(copy(l:fortran_exts), 'l:abs_base . "/*." . v:val')

  let l:files = []
  for l:pat in l:patterns
    let l:files += glob(l:pat, 0, 1)
  endfor

  let l:dirs = {}
  " Also include the base directory itself if it exists
  let l:dirs[a:rel_base] = 1

  for l:f in l:files
    let l:dir = fnamemodify(l:f, ':p:h')
    " Make relative to project root
    let l:rel = fnamemodify(l:dir, ':s?' . escape(a:root . '/', ' \') . '??')
    if !empty(l:rel) && l:rel !=# a:root
      let l:dirs[l:rel] = 1
    endif
  endfor

  return keys(l:dirs)
endfunction
"}}}1

" Generate or update .fortls manifest for fpm project {{{1
function! fortls#generate(...) abort
  let l:root = a:0 > 0 && !empty(a:1) ? a:1 : project#find_root()
  if empty(l:root) || !filereadable(l:root . '/fpm.toml')
    return 0
  endif

  let l:target_file = l:root . '/.fortls'

  " If .fortls already exists, check if it was created by vimf90
  if filereadable(l:target_file)
    try
      let l:existing_raw = join(readfile(l:target_file), '')
      let l:existing_json = json_decode(l:existing_raw)
      if type(l:existing_json) == v:t_dict && get(l:existing_json, '_generated_by', '') !=# 'vimf90'
        " Hand-crafted by user; preserve it
        return 0
      endif
    catch
      " If invalid JSON, do not overwrite user file
      return 0
    endtry
  endif

  " Standard fpm source roots
  let l:source_roots = ['src', 'app', 'test', 'example', 'examples']

  " Extract custom source-dir from fpm.toml if specified
  for l:line in readfile(l:root . '/fpm.toml')
    if l:line =~? '^\s*source-dir\s*='
      let l:custom = matchstr(l:line, '["'']\zs[^"'']\+\ze["'']')
      if !empty(l:custom) && index(l:source_roots, l:custom) == -1
        call add(l:source_roots, l:custom)
      endif
    endif
  endfor

  " Collect all source directories
  let l:all_source_dirs = {}
  for l:sroot in l:source_roots
    for l:sdir in s:find_source_subdirs(l:root, l:sroot)
      let l:all_source_dirs[l:sdir] = 1
    endfor
  endfor

  " Scan fpm dependencies in build/dependencies/*/src or include
  let l:dep_dirs = globpath(l:root . '/build/dependencies', '*', 0, 1)
  for l:dep in l:dep_dirs
    if isdirectory(l:dep)
      let l:dep_name = fnamemodify(l:dep, ':t')
      for l:sub in ['src', 'include', 'inc', 'app']
        let l:rel_dep_sub = 'build/dependencies/' . l:dep_name . '/' . l:sub
        for l:sdir in s:find_source_subdirs(l:root, l:rel_dep_sub)
          let l:all_source_dirs[l:sdir] = 1
        endfor
      endfor
    endif
  endfor

  let l:sorted_source_dirs = sort(keys(l:all_source_dirs))

  " Construct .fortls JSON payload
  let l:config = {
        \ '_generated_by': 'vimf90',
        \ 'source_dirs': l:sorted_source_dirs,
        \ 'excl_paths': ['build', '.git']
        \ }

  let l:new_json_str = json_encode(l:config)

  " Check if on-disk file is already up to date
  if filereadable(l:target_file)
    let l:cur_raw = join(readfile(l:target_file), '')
    if l:cur_raw ==# l:new_json_str
      return 1
    endif
  endif

  " Format JSON nicely (indent with 2 spaces)
  let l:lines = [
        \ '{',
        \ '  "_generated_by": "vimf90",',
        \ '  "source_dirs": ['
        \ ]
  let l:num_dirs = len(l:sorted_source_dirs)
  for l:i in range(l:num_dirs)
    let l:comma = (l:i < l:num_dirs - 1) ? ',' : ''
    call add(l:lines, '    "' . escape(l:sorted_source_dirs[l:i], '"\') . '"' . l:comma)
  endfor
  let l:lines += [
        \ '  ],',
        \ '  "excl_paths": [',
        \ '    "build",',
        \ '    ".git"',
        \ '  ]',
        \ '}'
        \ ]

  call writefile(l:lines, l:target_file)
  return 1
endfunction
"}}}1

let &cpo = s:save_cpo
unlet s:save_cpo
