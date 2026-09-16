"########################################################################
" File:          autoload/fortran_menu.vim
" Author:        Rudra Banerjee (bnrj DOT rudra at gmail.com)
" License:       GPLv3
" Description:   GUI menu definition for Fortran tools.
"
" The menu lives here rather than in the ftplugin so that it is reachable
" without a running GUI: ftplugin/fortran_menu.vim is only a guard, and the
" item list below can be inspected and installed by the test suite, which has
" no gui_running to offer.
"
" Menu path syntax, both of which have bitten this file:
"   * a dot separates path components, so a dot inside a LABEL must be
"     escaped -- an "Array..." label otherwise becomes three empty components
"     and Vim rejects the whole item with E792;
"   * a separator is an item whose name begins and ends with a hyphen.
"     Anything else is drawn as an ordinary entry, however it is named.
"########################################################################

let s:save_cpo = &cpo
set cpo&vim

" Name of the top-level menu.
function! fortran_menu#root() abort
  if exists('g:fortran_menu_name')
    return g:fortran_menu_name
  endif
  if get(g:, 'fortran_menu_dynamic_dialect', 0)
    let l:ext = tolower(expand('%:e'))
    if l:ext ==# 'f08' || l:ext ==# 'f2008'
      return '&Fortran\ 2008'
    elseif l:ext ==# 'f18' || l:ext ==# 'f2018'
      return '&Fortran\ 2018'
    elseif l:ext ==# 'f03' || l:ext ==# 'f2003'
      return '&Fortran\ 2003'
    elseif l:ext ==# 'f95'
      return '&Fortran\ 95'
    elseif l:ext ==# 'f90'
      return '&Fortran\ 90'
    elseif l:ext ==# 'f' || l:ext ==# 'for' || l:ext ==# 'f77'
      return '&Fortran\ 77'
    endif
  endif
  return '&Fortran'
endfunction

" Render a mapping into something displayable next to a menu entry.
function! s:shortcut(name, default) abort
  let l:key = get(b:, a:name, a:default)
  if empty(l:key)
    return ''
  endif
  let l:leader = get(g:, 'fortran_leader', get(g:, 'mapleader', '\'))
  let l:localleader = get(g:, 'maplocalleader', '\')
  let l:disp_leader = (l:leader ==# ' ') ? '<Space>' : l:leader
  let l:disp_localleader = (l:localleader ==# ' ') ? '<Space>' : l:localleader
  let l:res = substitute(l:key, '\c<leader>', escape(l:disp_leader, '\'), 'g')
  return substitute(l:res, '\c<localleader>', escape(l:disp_localleader, '\'), 'g')
endfunction

" The whole menu, as [path, shortcut, command] triples. Paths are written with
" the escaping Vim's menu parser expects: spaces and dots inside a label are
" backslash-escaped, dots between components are not.
function! fortran_menu#items() abort
  return [
        \ ['&Compile.&Compile',                       s:shortcut('fortran_compile', '\cc'),        ':FortranCompile<CR>'],
        \ ['&Compile.Generate\ &Executable',          s:shortcut('fortran_exe', '\ce'),            ':FortranExe<CR>'],
        \ ['&Compile.Compile\ &and\ Run',             s:shortcut('fortran_run', '\cr'),            ':FortranRun<CR>'],
        \ ['&Compile.Command\ Line\ &Arguments',      s:shortcut('fortran_cla', '\cl'),            ':FortranArgs<CR>'],
        \ ['&Compile.-sep_dbg-',                      '',                                          '<Nop>'],
        \ ['&Compile.Start\ &Debugger\ (GDB/DAP)',    s:shortcut('fortran_dbg', '\cd'),            ':FortranDebug<CR>'],
        \ ['&Compile.Toggle\ &Breakpoint',            s:shortcut('fortran_break_toggle', '\dt'),   ':FortranBreakpointToggle<CR>'],
        \ ['&Compile.&Inspect\ Matrix\ Array\.\.\.',  s:shortcut('fortran_inspect_array', '\da'),  ':FortranInspectArray<CR>'],
        \
        \ ['&FPM.fpm\ &Build',                        s:shortcut('fortran_fpm_build', '\fb'),      ':FortranFpmBuild<CR>'],
        \ ['&FPM.fpm\ &Run',                          s:shortcut('fortran_fpm_run', '\fr'),        ':FortranFpmRun<CR>'],
        \ ['&FPM.fpm\ &Test\ All',                    s:shortcut('fortran_fpm_test', '\ft'),       ':FortranFpmTest<CR>'],
        \ ['&FPM.fpm\ Test\ &Current\ File',          s:shortcut('fortran_fpm_test_cur', '\tc'),   ':FortranFpmTestCurrent<CR>'],
        \ ['&FPM.-sep_fpm-',                          '',                                          '<Nop>'],
        \ ['&FPM.fpm\ &New\ Project',                 '',                                          ':FortranFpmNew<CR>'],
        \ ['&FPM.fpm\ &Add\ Dependency\.\.\.',        '',                                          ':FortranFpmAdd '],
        \
        \ ['&Interactive.Toggle\ &LFortran\ REPL',    s:shortcut('fortran_repl_toggle', '\rt'),    ':FortranReplToggle<CR>'],
        \ ['&Interactive.Send\ &Line\ /\ Selection',  s:shortcut('fortran_repl_send', '\rs'),      ':FortranReplSend<CR>'],
        \ ['&Interactive.Send\ Enclosing\ &Subprogram', s:shortcut('fortran_repl_subprog', '\rm'), ':FortranReplSendSubprogram<CR>'],
        \ ['&Interactive.Send\ Entire\ &Buffer',      s:shortcut('fortran_repl_buffer', '\rb'),    ':FortranReplSendBuffer<CR>'],
        \ ['&Interactive.Restart\ &REPL',             '',                                          ':FortranReplRestart<CR>'],
        \ ['&Interactive.-sep_repl-',                 '',                                          '<Nop>'],
        \ ['&Interactive.Open\ Scientific\ &Scratchpad', s:shortcut('fortran_scratch', '\so'),     ':FortranScratch<CR>'],
        \ ['&Interactive.&Run\ Scratchpad',           s:shortcut('fortran_scratch_run', '\sr'),    ':FortranScratchRun<CR>'],
        \
        \ ['&HPC.Profile:\ &Debug',                   s:shortcut('fortran_profile', '\pp'),        ':FortranProfile debug<CR>'],
        \ ['&HPC.Profile:\ &Release',                 '',                                          ':FortranProfile release<CR>'],
        \ ['&HPC.Profile:\ &Fast\ Math',              '',                                          ':FortranProfile fast<CR>'],
        \ ['&HPC.Profile:\ &Sanitize',                '',                                          ':FortranProfile sanitize<CR>'],
        \ ['&HPC.-sep_hpc1-',                         '',                                          '<Nop>'],
        \ ['&HPC.Toggle\ &OpenMP',                    s:shortcut('fortran_openmp', '\po'),         ':FortranOpenMP<CR>'],
        \ ['&HPC.Toggle\ &MPI\ Wrapper',              s:shortcut('fortran_mpi', '\pm'),            ':FortranMPI<CR>'],
        \ ['&HPC.Toggle\ &GPU\ Offloading',           s:shortcut('fortran_gpu', '\pg'),            ':FortranGPU<CR>'],
        \ ['&HPC.-sep_hpc2-',                         '',                                          '<Nop>'],
        \ ['&HPC.Run\ &MPI\ Cluster\ Job',            s:shortcut('fortran_mpirun', '\pr'),         ':FortranMPIRun<CR>'],
        \
        \ ['&Documentation.Generate\ &FORD\ Docstring', s:shortcut('fortran_doc', '\dc'),          ':FortranDoc ford<CR>'],
        \ ['&Documentation.Generate\ &Doxygen\ Docstring', '',                                     ':FortranDoc doxygen<CR>'],
        \ ['&Documentation.-sep_doc-',                '',                                          '<Nop>'],
        \ ['&Documentation.&Build\ Project\ FORD\ Docs', s:shortcut('fortran_ford_build_map', '\db'), ':FordBuild<CR>'],
        \ ['&Documentation.&Preview\ FORD\ Docs\ in\ Browser', s:shortcut('fortran_ford_prev_map', '\dp'), ':FordPreview<CR>'],
        \
        \ ['&Project.&Build\ Project',                '',                                          ':FortranProjectBuild<CR>'],
        \ ['&Project.Generate\ &Tags',                s:shortcut('fortran_tags', '\tg'),           ':FortranTags<CR>'],
        \ ['&Project.Find\ &Module',                  s:shortcut('fortran_find_mod', '\fm'),       ':FortranFindModule<CR>'],
        \ ['&Project.-sep_proj-',                     '',                                          '<Nop>'],
        \ ['&Project.&Make\ (Fallback)',              s:shortcut('fortran_make', '\mk'),           ':FortranMake<CR>'],
        \ ['&Project.Make\ &Properties',              s:shortcut('fortran_makeProp', '\mp'),       ':FortranMakeArgs<CR>'],
        \
        \ ['-sep_top-',                               '',                                          '<Nop>'],
        \ ['&Format\ Buffer',                         '',                                          ':FortranFormat<CR>'],
        \ ['&Help',                                   'VimF90\ Help',                              ':help vimf90.txt<CR>'],
        \ ]
endfunction

" The full menu path of one item, shortcut column included.
function! fortran_menu#path(root, item) abort
  let [l:path, l:shortcut, l:cmd] = a:item
  let l:tab = !empty(l:shortcut) ? '<Tab>' . escape(l:shortcut, " \\|\t") : ''
  return a:root . '.' . l:path . l:tab
endfunction

" Install the menu for the current buffer and arrange for its removal.
function! fortran_menu#setup() abort
  let l:root = fortran_menu#root()

  " Clean up legacy/previous menus
  silent! execute 'aunmenu Fortran&90'
  silent! execute 'aunmenu &Fortran90'

  for l:item in fortran_menu#items()
    let l:mpath = fortran_menu#path(l:root, l:item)
    execute 'anoremenu <script> ' . l:mpath . ' ' . l:item[2]
    execute 'inoremenu <script> ' . l:mpath . ' <C-C>' . l:item[2]
  endfor

  let b:undo_ftplugin = (exists('b:undo_ftplugin') ? b:undo_ftplugin . ' | ' : '')
        \ . 'silent! aunmenu ' . l:root
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
