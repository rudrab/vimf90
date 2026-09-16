"########################################################################
" Filename:      autoload/project.vim
" Copyright:     Copyright (C) 2026 Rudra Banerjee
" License:       GPLv3
" Description:   Large multi-file Fortran project management, module search,
"                include path resolution, and tag generation
"########################################################################

let s:save_cpo = &cpo
set cpo&vim

" Find project root directory {{{1
function! project#find_root(...) abort
  let l:start_dir = a:0 > 0 && !empty(a:1) ? a:1 : expand('%:p:h')
  if empty(l:start_dir)
    let l:start_dir = getcwd()
  endif

  for l:indicator in ['fpm.toml', 'CMakeLists.txt', 'meson.build', 'Makefile', 'makefile', '.fortls', '.git']
    let l:found = findfile(l:indicator, l:start_dir . ';')
    if empty(l:found)
      let l:found = finddir(l:indicator, l:start_dir . ';')
    endif
    if !empty(l:found)
      return fnamemodify(l:found, ':p:h')
    endif
  endfor

  return l:start_dir
endfunction
"}}}1

" Detect project build system {{{1
function! project#detect_type(...) abort
  let l:root = a:0 > 0 ? a:1 : project#find_root()
  if filereadable(l:root . '/fpm.toml')
    return 'fpm'
  elseif filereadable(l:root . '/CMakeLists.txt')
    return 'cmake'
  elseif filereadable(l:root . '/meson.build')
    return 'meson'
  elseif filereadable(l:root . '/Makefile') || filereadable(l:root . '/makefile')
    return 'make'
  else
    return 'single'
  endif
endfunction
"}}}1

" Discover module (.mod) and include directories in the project {{{1
function! project#get_include_flags(...) abort
  let l:root = a:0 > 0 ? a:1 : project#find_root()
  let l:flags = []

  let l:candidate_dirs = [
        \ l:root,
        \ l:root . '/src',
        \ l:root . '/include',
        \ l:root . '/inc',
        \ l:root . '/build',
        \ l:root . '/build/include',
        \ l:root . '/build/modules',
        \ ]

  " Check fpm build output directories
  let l:fpm_build_dirs = globpath(l:root . '/build', 'gfortran_*', 0, 1) + globpath(l:root . '/build', 'ifx_*', 0, 1)
  for l:fdir in l:fpm_build_dirs
    call add(l:candidate_dirs, l:fdir)
  endfor

  for l:dir in l:candidate_dirs
    if isdirectory(l:dir)
      call add(l:flags, '-I' . fnameescape(l:dir))
    endif
  endfor

  return join(l:flags, ' ')
endfunction
"}}}1

" Universal Project Build {{{1
function! project#build(...) abort
  let l:root = project#find_root()
  let l:type = project#detect_type(l:root)
  let l:args = a:0 > 0 ? a:1 : ''

  if l:type ==# 'fpm'
    return fpm#build(l:args)
  elseif l:type ==# 'cmake'
    let l:build_dir = isdirectory(l:root . '/build') ? 'build' : '.'
    let l:cmd = 'cmake --build ' . l:build_dir . ' ' . l:args
    echomsg 'Building CMake project in ' . l:root . '...'
    execute 'silent make! -C ' . fnameescape(l:root . '/' . l:build_dir)
  elseif l:type ==# 'make'
    let l:orig_dir = getcwd()
    try
      execute 'lcd ' . fnameescape(l:root)
      call makes#MakeRun()
    finally
      execute 'lcd ' . fnameescape(l:orig_dir)
    endtry
  else
    return makes#Fcompile()
  endif
endfunction
"}}}1

" Generate Ctags for large Fortran project {{{1
function! project#generate_tags() abort
  let l:root = project#find_root()
  if !executable('ctags')
    echohl ErrorMsg | echo 'ctags (Universal Ctags) is not installed or not in PATH.' | echohl None
    return
  endif

  let l:tagfile = l:root . '/tags'
  echon 'Generating tags for Fortran project in ' . fnamemodify(l:root, ':t') . ' ...'

  let l:cmd = 'ctags --languages=Fortran --language-force=Fortran -R -f ' . fnameescape(l:tagfile) . ' ' . fnameescape(l:root)
  execute 'silent !' . l:cmd
  redraw!

  if filereadable(l:tagfile)
    execute 'setlocal tags+=' . fnameescape(l:tagfile)
    echomsg 'Fortran tags updated at ' . l:tagfile
  else
    echohl ErrorMsg | echo 'Tag generation failed.' | echohl None
  endif
endfunction
"}}}1

" Jump to module file across project {{{1
function! project#find_module(name) abort
  let l:mod_name = !empty(a:name) ? a:name : input('Find module name: ')
  if empty(l:mod_name)
    return
  endif

  let l:root = project#find_root()
  let l:pattern = '\c^\s*module\s\+' . l:mod_name . '\b'

  " Search for files in project
  let l:files = globpath(l:root, '**/*.{f90,f95,f03,f08,F90,F95,f,F}', 0, 1)
  for l:file in l:files
    for l:line in readfile(l:file, '', 100)
      if l:line =~? l:pattern
        execute 'edit ' . fnameescape(l:file)
        call search(l:pattern, 'w')
        echomsg 'Found module ' . l:mod_name . ' in ' . fnamemodify(l:file, ':.')
        return
      endif
    endfor
  endfor

  echohl WarningMsg | echo 'Module "' . l:mod_name . '" not found in project.' | echohl None
endfunction
"}}}1

let &cpo = s:save_cpo
unlet s:save_cpo
