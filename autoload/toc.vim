"########################################################################
" File:          autoload/toc.vim
" Author:        Rudra Banerjee (bnrj DOT rudra at gmail.com)
" License:       GPLv3
" Description:   Native Fortran Table of Contents / Outline sidebar (:FortranToc)
"########################################################################

let s:save_cpo = &cpo
set cpo&vim

" The source buffer whose outline we are showing.
let s:toc_source_bufnr = -1

" Pattern fragments for construct declarations (free-form).
" Each pattern ensures (\w+) is group 1.
"
" A module is named anything but the keywords that make `module` a prefix
" (module procedure, module subroutine, module function). The exclusion needs
" a word boundary, or a module merely named procedures_mod is dropped.
"
" A derived type may be declared with or without `::`. Without it, `type is`
" has to be excluded: that is a guard inside SELECT TYPE, not a declaration.
" `type(name)` never matches either form, since it is followed by a paren.
let s:decl_bodies = {
      \ 'program':    'program\s+(\w+)',
      \ 'module':     'module\s+%(%(procedure|subroutine|function)>)@!(\w+)',
      \ 'submodule':  'submodule\s*\([^)]+\)\s*(\w+)',
      \ 'subroutine': '%(%(pure|elemental|recursive|impure|non_recursive|module)\s+)*subroutine\s+(\w+)',
      \ 'function':   '%(%(pure|elemental|recursive|impure|non_recursive|module)\s+)*%(%(integer|real|complex|logical|character|double\s+precision|type|class)%(\s*\*\s*\d+|\s*\(.*\))?\s+%(%(pure|elemental|recursive|impure|non_recursive|module)\s+)*)?function\s+(\w+)',
      \ 'type':       'type%(%(\s*,\s*%(public|private|abstract|bind\s*\([^)]*\)|extends\s*\([^)]+\)))*\s*::\s*|\s+%(is>)@!)(\w+)',
      \ 'interface':  '%(abstract\s+)?interface%(\s+(\w+))?',
      \ 'block_data': 'block\s*data%(\s+(\w+))?',
      \ }

" Free form: only blanks before the statement. Fixed form: an optional
" statement label as well; comment lines are skipped before matching, so column
" one needs no handling here. The trailing word boundary keeps a keyword from
" matching the front of a longer identifier, as in `interfaces = 1`.
let s:decl_patterns = map(copy(s:decl_bodies), {_, b -> '\v\c^\s*' . b . '>'})
let s:decl_patterns_fixed = map(copy(s:decl_bodies), {_, b -> '\v\c^\s*%(\d+\s+)?' . b . '>'})

" Ordering for scanning lines: module/program before subprograms.
let s:kind_order = ['program', 'module', 'submodule', 'block_data',
      \ 'interface', 'type', 'subroutine', 'function']

" Short tag labels for the sidebar.
let s:kind_labels = {
      \ 'program': 'PRG', 'module': 'MOD', 'submodule': 'SBM',
      \ 'subroutine': 'SUB', 'function': 'FUN', 'type': 'TYP',
      \ 'interface': 'INT', 'block_data': 'BLK'
      \ }

" Declarations in a list of source lines. `path` is the file the lines came
" from; it is what a jump opens, so the file need not be loaded to be listed.
function! s:scan_lines(lines, fixed, path) abort
  let l:pats = a:fixed ? s:decl_patterns_fixed : s:decl_patterns
  let l:entries = []

  for l:i in range(len(a:lines))
    let l:line = a:lines[l:i]
    " Comments, and fixed-form continuation lines: a continuation carries on
    " the statement above and never begins a declaration of its own.
    if l:line =~# '^\s*!'
      continue
    endif
    if a:fixed && (l:line =~# '^[cC*]' || l:line =~# '^[ 0-9]\{5}[^ 0]')
      continue
    endif

    for l:kind in s:kind_order
      let l:m = matchlist(l:line, l:pats[l:kind])
      if !empty(l:m)
        let l:name = !empty(l:m[1]) ? l:m[1] : (l:kind ==# 'interface' ? '(anonymous)' : '(unnamed)')
        " Units inside a module or program are shown one level in.
        let l:indent = len(matchstr(l:line, '^\s*'))
        let l:toplevel = index(['program', 'module', 'submodule', 'block_data'], l:kind) >= 0
        call add(l:entries, {
              \ 'lnum': l:i + 1,
              \ 'kind': l:kind,
              \ 'name': l:name,
              \ 'depth': l:toplevel ? 0 : (l:indent > (a:fixed ? 6 : 0) ? 1 : 0),
              \ 'path': a:path,
              \ 'file': fnamemodify(a:path, ':t'),
              \ })
        break
      endif
    endfor
  endfor

  return l:entries
endfunction

" Declarations in a loaded buffer, including unsaved edits.
function! s:scan_buffer(bufnr) abort
  return s:scan_lines(getbufline(a:bufnr, 1, '$'), s:buf_is_fixed(a:bufnr),
        \ fnamemodify(bufname(a:bufnr), ':p'))
endfunction

" Declarations in a file. A file already open in the editor is read from its
" buffer so that unsaved edits show; anything else is read from disk. Nothing
" is loaded or added to the buffer list, which on a real project would mean
" hundreds of entries in :ls from a single outline.
function! s:scan_file(path) abort
  for l:info in getbufinfo({'bufloaded': 1})
    if !empty(l:info.name) && fnamemodify(l:info.name, ':p') ==# a:path
      return s:scan_buffer(l:info.bufnr)
    endif
  endfor
  try
    let l:lines = readfile(a:path)
  catch
    return []
  endtry
  return s:scan_lines(l:lines, s:path_is_fixed(a:path), a:path)
endfunction

" Fixed source form, decided as Vim's own fortran ftplugin decides it.
function! s:buf_is_fixed(bufnr) abort
  let l:val = getbufvar(a:bufnr, 'fortran_fixed_source', -1)
  if l:val != -1
    return l:val ? 1 : 0
  endif
  return s:path_is_fixed(bufname(a:bufnr))
endfunction

function! s:path_is_fixed(path) abort
  if exists('g:fortran_free_source')
    return 0
  endif
  if exists('g:fortran_fixed_source')
    return 1
  endif
  return fnamemodify(a:path, ':e') =~? '^\%(f\|f77\|for\|ftn\)$' ? 1 : 0
endfunction

" Format entries into lines for the sidebar.
function! s:format_entries(entries, multi_file) abort
  let l:lines = []
  let l:lnums = []
  let l:paths = []
  let l:last_file = ''

  for l:e in a:entries
    if a:multi_file && l:e.file !=# l:last_file
      if !empty(l:lines)
        call add(l:lines, '')
        call add(l:lnums, 0)
        call add(l:paths, '')
      endif
      call add(l:lines, '== ' . l:e.file . ' ==')
      call add(l:lnums, 1)
      call add(l:paths, l:e.path)
      let l:last_file = l:e.file
    endif

    let l:indent = repeat('  ', l:e.depth)
    let l:tag = get(s:kind_labels, l:e.kind, '???')
    let l:line_str = printf('%s[%s] %-20s  :%d', l:indent, l:tag, l:e.name, l:e.lnum)
    call add(l:lines, l:line_str)
    call add(l:lnums, l:e.lnum)
    call add(l:paths, l:e.path)
  endfor

  return [l:lines, l:lnums, l:paths]
endfunction

" Open or focus the TOC sidebar.
function! toc#show(...) abort
  let l:bang = a:0 > 0 && a:1 ==# '!'
  let l:source_bufnr = bufnr('%')
  let l:source_winnr = winnr()
  let s:toc_source_bufnr = l:source_bufnr

  if l:bang || &filetype !=# 'fortran'
    let l:entries = s:scan_project()
    let l:multi_file = 1
  else
    let l:entries = s:scan_buffer(l:source_bufnr)
    let l:multi_file = 0
  endif

  if empty(l:entries)
    echomsg 'vimf90: No Fortran declarations found.'
    return
  endif

  let [l:lines, l:lnums, l:paths] = s:format_entries(l:entries, l:multi_file)

  let l:toc_winnr = s:find_toc_window()
  if l:toc_winnr > 0
    execute l:toc_winnr . 'wincmd w'
  else
    let l:width = get(g:, 'fortran_toc_width', 35)
    let l:pos = get(g:, 'fortran_toc_position', 'left')
    let l:split_cmd = (l:pos ==# 'right' ? 'botright' : 'topleft') . ' vertical ' . l:width . 'new'
    execute l:split_cmd
    setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted
    setlocal nowrap nonumber norelativenumber signcolumn=no
    setlocal filetype=fortran_toc
    setlocal winfixwidth
    file [Fortran\ TOC]

    " Navigation mappings
    nnoremap <buffer> <silent> <CR>  :call toc#jump()<CR>
    nnoremap <buffer> <silent> o     :call toc#jump()<CR>
    nnoremap <buffer> <silent> q     :call toc#close()<CR>
    nnoremap <buffer> <silent> r     :call toc#refresh()<CR>
    nnoremap <buffer> <silent> <C-l> :call toc#refresh()<CR>
    
    " Simple syntax highlight
    syntax match FortranTocTag /\[[A-Z]\{3\}\]/
    syntax match FortranTocLineNum /:\d\+$/
    syntax match FortranTocHeader /^== .* ==$/
    highlight default link FortranTocTag Type
    highlight default link FortranTocLineNum Comment
    highlight default link FortranTocHeader Title
  endif

  setlocal modifiable
  silent %delete _
  call setline(1, l:lines)
  setlocal nomodifiable nomodified

  let b:toc_lnums = l:lnums
  let b:toc_paths = l:paths
  let b:toc_is_multi = l:multi_file
  call cursor(1, 1)
endfunction

" Jump to declaration under cursor in the TOC.
function! toc#jump() abort
  let l:idx = line('.') - 1
  if !exists('b:toc_lnums') || l:idx < 0 || l:idx >= len(b:toc_lnums)
    return
  endif
  let l:lnum = b:toc_lnums[l:idx]
  let l:path = b:toc_paths[l:idx]
  if l:lnum <= 0 || empty(l:path)
    return
  endif

  " A window already showing the file wins.
  let l:target = 0
  for l:w in range(1, winnr('$'))
    let l:name = bufname(winbufnr(l:w))
    if !empty(l:name) && fnamemodify(l:name, ':p') ==# l:path
      let l:target = l:w
      break
    endif
  endfor

  if l:target > 0
    execute l:target . 'wincmd w'
  else
    " Otherwise the window the user came from, or failing that any window that
    " is not the outline; with none left, make one.
    wincmd p
    if &filetype ==# 'fortran_toc'
      let l:other = 0
      for l:w in range(1, winnr('$'))
        if getbufvar(winbufnr(l:w), '&filetype') !=# 'fortran_toc'
          let l:other = l:w
          break
        endif
      endfor
      if l:other > 0
        execute l:other . 'wincmd w'
      else
        execute (get(g:, 'fortran_toc_position', 'left') ==# 'right' ? 'topleft' : 'botright') . ' vnew'
      endif
    endif
    " Files from a project scan are not loaded until they are jumped to. Do not
    " throw away unsaved changes in the window being reused.
    if &modified && !&hidden
      execute 'split ' . fnameescape(l:path)
    else
      execute 'edit ' . fnameescape(l:path)
    endif
  endif

  execute l:lnum
  normal! zz
endfunction

" Refresh the TOC buffer.
function! toc#refresh() abort
  if s:toc_source_bufnr <= 0 || !bufexists(s:toc_source_bufnr)
    return
  endif
  let l:cur_line = line('.')
  let l:multi = exists('b:toc_is_multi') && b:toc_is_multi
  if l:multi
    let l:entries = s:scan_project()
  else
    let l:entries = s:scan_buffer(s:toc_source_bufnr)
  endif

  let [l:lines, l:lnums, l:paths] = s:format_entries(l:entries, l:multi)

  setlocal modifiable
  silent %delete _
  call setline(1, l:lines)
  setlocal nomodifiable nomodified

  let b:toc_lnums = l:lnums
  let b:toc_paths = l:paths
  call cursor(min([l:cur_line, len(l:lines)]), 1)
endfunction

" Close the TOC window.
function! toc#close() abort
  let l:win = s:find_toc_window()
  if l:win > 0
    execute l:win . 'wincmd w'
    close
  endif
endfunction

" Toggle the TOC window.
function! toc#toggle(...) abort
  let l:win = s:find_toc_window()
  if l:win > 0
    call toc#close()
  else
    let l:bang = a:0 > 0 ? a:1 : ''
    call toc#show(l:bang)
  endif
endfunction

" Find existing TOC window if open.
function! s:find_toc_window() abort
  for l:w in range(1, winnr('$'))
    if getbufvar(winbufnr(l:w), '&filetype') ==# 'fortran_toc'
      return l:w
    endif
  endfor
  return 0
endfunction

" Scan all project Fortran files.
" Fortran sources under the project root, in a stable order. Walked with
" readdir() rather than globbed, since the root is a path and not a pattern:
" a project directory containing a space or brackets must not be misread.
" build/ is skipped -- it holds fpm's copies of the sources -- as are VCS and
" other hidden directories.
function! s:project_files(dir, depth) abort
  if a:depth > 20
    return []
  endif
  let l:files = []
  for l:entry in sort(readdir(a:dir))
    let l:full = a:dir . '/' . l:entry
    if isdirectory(l:full)
      if l:entry !~# '^\.' && (a:depth > 0 || l:entry !=# 'build')
        let l:files += s:project_files(l:full, a:depth + 1)
      endif
    elseif l:entry =~? '\.\%(f\|for\|f77\|ftn\|f90\|f95\|f03\|f08\|f18\)$'
      call add(l:files, l:full)
    endif
  endfor
  return l:files
endfunction

function! s:scan_project() abort
  let l:root = project#find_root()
  if empty(l:root) || !isdirectory(l:root)
    let l:root = expand('%:p:h')
  endif
  let l:root = fnamemodify(l:root, ':p:s?/$??')

  let l:entries = []
  for l:f in s:project_files(l:root, 0)
    let l:entries += s:scan_file(l:f)
  endfor
  return l:entries
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
