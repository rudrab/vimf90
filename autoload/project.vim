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
  " Allow the root to be supplied by an external project manager, but only when
  " the caller has not named a directory to search from: an explicit argument is
  " a question about that directory, not about the current project.
  if a:0 == 0 || empty(a:1)
    if exists('b:fortran_project_root') && !empty(b:fortran_project_root)
      return expand(b:fortran_project_root)
    elseif exists('g:fortran_project_root') && !empty(g:fortran_project_root)
      return expand(g:fortran_project_root)
    endif

    for l:provider in ['g:Fortran_root_provider', 'g:fortran_root_provider']
      if exists(l:provider)
        let l:provided = call(eval(l:provider), [])
        if !empty(l:provided)
          return expand(l:provided)
        endif
      endif
    endfor
  endif

  let l:start_dir = a:0 > 0 && !empty(a:1) ? a:1 : expand('%:p:h')
  if empty(l:start_dir)
    let l:start_dir = getcwd()
  endif

  " findfile()/finddir() take a path list, in which a space separates entries,
  " so directories containing spaces have to be escaped.
  let l:search_path = escape(l:start_dir, ' ,') . ';'

  for l:indicator in ['fpm.toml', 'CMakeLists.txt', 'meson.build', 'Makefile', 'makefile', '.fortls', '.git']
    let l:found = findfile(l:indicator, l:search_path)
    if empty(l:found)
      let l:found = finddir(l:indicator, l:search_path)
    endif
    if !empty(l:found)
      let l:full_path = fnamemodify(l:found, ':p')
      if isdirectory(l:found) || l:found =~# '\.git$'
        return fnamemodify(l:full_path, ':h:h')
      else
        return fnamemodify(l:full_path, ':h')
      endif
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

" Extract include and module directories from build/compile_commands.json {{{1
function! s:get_compile_commands_dirs(root) abort
  let l:cc_file = a:root . '/build/compile_commands.json'
  if !filereadable(l:cc_file)
    return []
  endif

  let l:dirs = {}
  try
    let l:content = join(readfile(l:cc_file), '')
    if empty(l:content)
      return []
    endif
    let l:entries = json_decode(l:content)
    if type(l:entries) != v:t_list
      return []
    endif

    for l:entry in l:entries
      let l:cmd_tokens = []
      if has_key(l:entry, 'arguments') && type(l:entry.arguments) == v:t_list
        let l:cmd_tokens = l:entry.arguments
      elseif has_key(l:entry, 'command')
        let l:cmd_tokens = split(l:entry.command)
      endif

      let l:i = 0
      while l:i < len(l:cmd_tokens)
        let l:tok = l:cmd_tokens[l:i]
        let l:target_dir = ''
        if l:tok =~# '^-I.\+'
          let l:target_dir = l:tok[2:]
        elseif l:tok ==# '-I' && l:i + 1 < len(l:cmd_tokens)
          let l:i += 1
          let l:target_dir = l:cmd_tokens[l:i]
        elseif l:tok =~# '^-J.\+'
          let l:target_dir = l:tok[2:]
        elseif l:tok ==# '-J' && l:i + 1 < len(l:cmd_tokens)
          let l:i += 1
          let l:target_dir = l:cmd_tokens[l:i]
        elseif (l:tok ==# '-module' || l:tok ==# '-module-dir') && l:i + 1 < len(l:cmd_tokens)
          let l:i += 1
          let l:target_dir = l:cmd_tokens[l:i]
        endif

        if !empty(l:target_dir)
          let l:target_dir = substitute(l:target_dir, '^["'']\(.*\)["'']$', '\1', '')
          let l:full_dir = (l:target_dir =~# '^/' || l:target_dir =~# '^[A-Za-z]:[/\\]') ? l:target_dir : (a:root . '/' . l:target_dir)
          let l:full_dir = simplify(l:full_dir)
          if isdirectory(l:full_dir)
            let l:dirs[l:full_dir] = 1
          endif
        endif
        let l:i += 1
      endwhile
    endfor
  catch
    return []
  endtry

  return keys(l:dirs)
endfunction
"}}}1

" Discover module (.mod) and include directories in the project {{{1
function! project#get_include_dirs(...) abort
  let l:root = a:0 > 0 ? a:1 : project#find_root()

  " compile_commands.json names the module directory of the last build, so it
  " goes first. It is not a complete picture though: it records only the
  " targets of the last fpm command and carries no include/ or inc/ paths, so
  " the heuristic candidates are appended rather than replaced. They also serve
  " as the fallback module dirs when the manifest lags behind a profile switch.
  let l:dirs = s:get_compile_commands_dirs(l:root)

  let l:candidate_dirs = [
        \ l:root,
        \ l:root . '/src',
        \ l:root . '/include',
        \ l:root . '/inc',
        \ l:root . '/build',
        \ l:root . '/build/include',
        \ l:root . '/build/modules',
        \ ]

  " fpm build output directories, named <compiler>_<hash>. Matched by shape so
  " that nvfortran, flang, ifort and friends are covered too, and so that
  " build/dependencies is not mistaken for one.
  for l:bdir in globpath(l:root . '/build', '*', 0, 1)
    if fnamemodify(l:bdir, ':t') =~# '^\w\+_[0-9A-Fa-f]\{8,\}$'
      call add(l:candidate_dirs, l:bdir)
    endif
  endfor

  let l:seen = {}
  for l:dir in l:dirs
    let l:seen[l:dir] = 1
  endfor

  for l:dir in l:candidate_dirs
    if isdirectory(l:dir) && !has_key(l:seen, l:dir)
      let l:seen[l:dir] = 1
      call add(l:dirs, l:dir)
    endif
  endfor

  return l:dirs
endfunction

function! project#get_include_flags(...) abort
  let l:dirs = project#get_include_dirs(a:0 > 0 ? a:1 : project#find_root())
  return join(map(l:dirs, '"-I" . fnameescape(v:val)'), ' ')
endfunction
"}}}1

" Universal Project Build {{{1
function! project#build(...) abort
  let l:root = project#find_root()
  let l:type = project#detect_type(l:root)
  let l:args = a:0 > 0 ? a:1 : ''

  " Allow delegation to external build providers (e.g. vim-dispatch, asyncrun)
  for l:provider in ['g:Fortran_build_provider', 'g:fortran_build_provider']
    if exists(l:provider)
      let l:handled = call(eval(l:provider), [{'root': l:root, 'type': l:type, 'args': l:args}])
      if l:handled
        return 1
      endif
    endif
  endfor

  if l:type ==# 'fpm'
    return fpm#build(l:args)
  elseif l:type ==# 'cmake'
    let l:build_dir = isdirectory(l:root . '/build') ? 'build' : '.'
    let l:cmd = 'cmake --build ' . fnameescape(l:root . '/' . l:build_dir) . (!empty(l:args) ? (' ' . l:args) : '')
    echomsg 'Building CMake project in ' . l:root . '...'
    let l:makeprg_saved = &l:makeprg
    try
      let &l:makeprg = l:cmd
      execute 'silent make!'
      redraw!
      botright cwindow
    finally
      let &l:makeprg = l:makeprg_saved
    endtry
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
  let l:pattern = '\c^\s*module\s\+' . l:mod_name . '\>'

  " Let :vimgrep scan the project rather than reading every source file into a
  " Vim list. 'j' keeps the cursor here until we know where to jump, and the
  " quickfix list is restored afterwards so build results survive the search.
  let l:saved_qf = getqflist({'items': 1, 'title': 1})
  let l:matches = []
  try
    execute 'noautocmd vimgrep /' . escape(l:pattern, '/') . '/j '
          \ . fnameescape(l:root) . '/**/*.{f90,f95,f03,f08,F90,F95,f,F}'
    let l:matches = getqflist()
  catch /^Vim\%((\a\+)\)\=:E\%(479\|480\|683\)/
    " No matching line, or no source files to search
  finally
    " Restore by content, not by list id: vimgrep pushed a new list onto the
    " stack, and the saved id would update that older entry instead of this one.
    call setqflist([], 'r', {
          \ 'items': get(l:saved_qf, 'items', []),
          \ 'title': get(l:saved_qf, 'title', ''),
          \ })
  endtry

  if empty(l:matches)
    echohl WarningMsg | echo 'Module "' . l:mod_name . '" not found in project.' | echohl None
    return
  endif

  let l:file = fnamemodify(bufname(l:matches[0].bufnr), ':p')
  execute 'edit ' . fnameescape(l:file)
  call cursor(l:matches[0].lnum, 1)
  echomsg 'Found module ' . l:mod_name . ' in ' . fnamemodify(l:file, ':.')
endfunction
"}}}1

let &cpo = s:save_cpo
unlet s:save_cpo
