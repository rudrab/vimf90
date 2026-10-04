"########################################################################
" File:          autoload/fortls.vim
" Author:        Rudra Banerjee (bnrj DOT rudra at gmail.com)
" License:       GPLv3
" Description:   Automated .fortls LSP configuration generator for fpm projects
"########################################################################

let s:save_cpo = &cpo
set cpo&vim

" Discover all directories containing Fortran source files under a base dir {{{1
let s:fortran_file_pattern = '\.\%(f\|for\|f77\|f90\|f95\|f03\|f08\)$'

" Walk with readdir() rather than glob(): the base path is data, not a pattern,
" so a project directory containing [ ] * ? or { } cannot be misread as a glob.
" Paths are assembled by concatenation and made relative with strpart(), which
" keeps regular-expression metacharacters out of the picture entirely.
function! s:collect_source_dirs(root, rel, acc, depth) abort
  if a:depth > 20
    return
  endif

  let l:abs = empty(a:rel) ? a:root : a:root . '/' . a:rel
  if !isdirectory(l:abs)
    return
  endif

  let l:has_source = 0
  for l:entry in readdir(l:abs)
    let l:child = l:abs . '/' . l:entry
    if isdirectory(l:child)
      call s:collect_source_dirs(a:root, empty(a:rel) ? l:entry : a:rel . '/' . l:entry,
            \ a:acc, a:depth + 1)
    elseif l:entry =~? s:fortran_file_pattern
      let l:has_source = 1
    endif
  endfor

  " The base of a source root is always listed so that fortls sees it even
  " before any sources exist; nested directories only earn a place if they
  " actually hold Fortran files.
  if l:has_source || a:depth == 0
    let a:acc[a:rel] = 1
  endif
endfunction

function! s:find_source_subdirs(root, rel_base) abort
  let l:acc = {}
  call s:collect_source_dirs(a:root, a:rel_base, l:acc, 0)
  return keys(l:acc)
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

  " Scan fpm dependencies in build/dependencies/*/src or include. readdir()
  " again rather than globpath(): the root is a path, not a pattern, and a
  " project directory containing braces or brackets would otherwise be expanded.
  let l:dep_root = l:root . '/build/dependencies'
  if isdirectory(l:dep_root)
    for l:dep_name in readdir(l:dep_root)
      if !isdirectory(l:dep_root . '/' . l:dep_name)
        continue
      endif
      for l:sub in ['src', 'include', 'inc', 'app']
        let l:rel_dep_sub = 'build/dependencies/' . l:dep_name . '/' . l:sub
        for l:sdir in s:find_source_subdirs(l:root, l:rel_dep_sub)
          let l:all_source_dirs[l:sdir] = 1
        endfor
      endfor
    endfor
  endif

  let l:sorted_source_dirs = sort(keys(l:all_source_dirs))

  " Construct the .fortls payload. It is written out by hand rather than with
  " json_encode() so that the file stays readable and diffable for whoever has
  " to look at it later.
  "
  " excl_paths is inert while source_dirs is non-empty, because fortls only
  " walks the tree when no source directory is configured. It is kept for
  " exactly that case: a project whose source roots do not exist yet falls back
  " to the walk, and build/ must not be dragged in when it does.
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

  " Rewrite only on a real change, so that a rebuild does not touch the file's
  " mtime for nothing. The comparison is against the formatted lines that are
  " about to be written, not a compact encoding of them.
  if filereadable(l:target_file) && readfile(l:target_file) ==# l:lines
    return 1
  endif

  call writefile(l:lines, l:target_file)
  return 1
endfunction
"}}}1

let &cpo = s:save_cpo
unlet s:save_cpo
