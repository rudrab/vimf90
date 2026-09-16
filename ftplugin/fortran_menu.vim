"########################################################################
" File:          ftplugin/fortran_menu.vim
" Author:        Rudra Banerjee (bnrj DOT rudra at gmail.com)
" Version:       0.6
" License:       GPLv3
" Description:   GUI Menu for Fortran tools with dynamic leader display,
"                profiles, fpm, docstrings, and project tools
"########################################################################

let s:save_cpo = &cpo
set cpo&vim

if !exists('g:Fortran_menumode')
  let g:Fortran_menumode = 1
endif

if has('gui_running') && has('menu') && g:Fortran_menumode == 1
  function! s:get_menu_root() abort
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

  function! s:format_shortcut(key) abort
    if empty(a:key)
      return ''
    endif
    let l:leader = get(g:, 'fortran_leader', get(g:, 'mapleader', '\'))
    let l:localleader = get(g:, 'maplocalleader', '\')
    let l:res = a:key
    " If leader is whitespace, display as <Space>
    let l:disp_leader = (l:leader ==# ' ') ? '<Space>' : l:leader
    let l:disp_localleader = (l:localleader ==# ' ') ? '<Space>' : l:localleader
    let l:res = substitute(l:res, '\c<leader>', escape(l:disp_leader, '\'), 'g')
    let l:res = substitute(l:res, '\c<localleader>', escape(l:disp_localleader, '\'), 'g')
    return l:res
  endfunction

  let s:root = s:get_menu_root()

  " Clean up legacy/previous menus
  silent! execute 'aunmenu Fortran&90'
  silent! execute 'aunmenu &Fortran90'

  " Shortcut resolutions
  let s:c_comp       = s:format_shortcut(get(b:, 'fortran_compile',   '\cc'))
  let s:c_exe        = s:format_shortcut(get(b:, 'fortran_exe',       '\ce'))
  let s:c_run        = s:format_shortcut(get(b:, 'fortran_run',       '\cr'))
  let s:c_cla        = s:format_shortcut(get(b:, 'fortran_cla',       '\cl'))
  let s:c_dbg        = s:format_shortcut(get(b:, 'fortran_dbg',       '\cd'))
  let s:c_fpm_build  = s:format_shortcut(get(b:, 'fortran_fpm_build', '\fb'))
  let s:c_fpm_run    = s:format_shortcut(get(b:, 'fortran_fpm_run',   '\fr'))
  let s:c_fpm_test   = s:format_shortcut(get(b:, 'fortran_fpm_test',  '\ft'))
  let s:c_tags       = s:format_shortcut(get(b:, 'fortran_tags',      '\tg'))
  let s:c_find_mod   = s:format_shortcut(get(b:, 'fortran_find_mod',  '\fm'))
  let s:c_doc        = s:format_shortcut(get(b:, 'fortran_doc',       '\dc'))
  let s:c_prof       = s:format_shortcut(get(b:, 'fortran_profile',   '\pp'))
  let s:c_omp        = s:format_shortcut(get(b:, 'fortran_openmp',    '\po'))
  let s:c_mpi        = s:format_shortcut(get(b:, 'fortran_mpi',       '\pm'))
  let s:c_make       = s:format_shortcut(get(b:, 'fortran_make',      '\mk'))
  let s:c_prop       = s:format_shortcut(get(b:, 'fortran_makeProp',  '\mp'))
  let s:c_proj       = s:format_shortcut(get(b:, 'fortran_genProj',   '\gp'))

  " Helper for adding menu item
  function! s:add_menu_item(path, shortcut, cmd) abort
    let l:tab = !empty(a:shortcut) ? '<Tab>' . escape(a:shortcut, " \\|\t") : ''
    let l:mpath = s:root . '.' . a:path . l:tab
    execute 'anoremenu <script> ' . l:mpath . ' ' . a:cmd
    execute 'inoremenu <script> ' . l:mpath . ' <C-C>' . a:cmd
  endfunction

  " Compile Submenu
  call s:add_menu_item('&Compile.&Compile', s:c_comp, ':FortranCompile<CR>')
  call s:add_menu_item('&Compile.Generate\ &Executable', s:c_exe, ':FortranExe<CR>')
  call s:add_menu_item('&Compile.Compile\ &and\ Run', s:c_run, ':FortranRun<CR>')
  call s:add_menu_item('&Compile.Command\ Line\ &Arguments', s:c_cla, ':FortranArgs<CR>')
  call s:add_menu_item('&Compile.Run\ &Debugger', s:c_dbg, ':FortranDebug<CR>')

  " Fortran Package Manager (fpm) Submenu
  call s:add_menu_item('&FPM.fpm\ &Build', s:c_fpm_build, ':FortranFpmBuild<CR>')
  call s:add_menu_item('&FPM.fpm\ &Run', s:c_fpm_run, ':FortranFpmRun<CR>')
  call s:add_menu_item('&FPM.fpm\ &Test', s:c_fpm_test, ':FortranFpmTest<CR>')
  call s:add_menu_item('&FPM.fpm\ &New\ Project', '', ':FortranFpmNew<CR>')

  " Build Profiles & Presets Submenu
  call s:add_menu_item('&Profiles.Profile:\ &Debug', s:c_prof, ':FortranProfile debug<CR>')
  call s:add_menu_item('&Profiles.Profile:\ &Release', '', ':FortranProfile release<CR>')
  call s:add_menu_item('&Profiles.Profile:\ &Fast\ Math', '', ':FortranProfile fast<CR>')
  call s:add_menu_item('&Profiles.Profile:\ &Sanitize', '', ':FortranProfile sanitize<CR>')
  call s:add_menu_item('&Profiles.sep_prof', '', '<Nop>')
  call s:add_menu_item('&Profiles.Toggle\ &OpenMP', s:c_omp, ':FortranOpenMP<CR>')
  call s:add_menu_item('&Profiles.Toggle\ &MPI', s:c_mpi, ':FortranMPI<CR>')

  " Documentation Submenu
  call s:add_menu_item('&Documentation.Generate\ &FORD\ Docstring', s:c_doc, ':FortranDoc ford<CR>')
  call s:add_menu_item('&Documentation.Generate\ &Doxygen\ Docstring', '', ':FortranDoc doxygen<CR>')

  " Project & Tools Submenu
  call s:add_menu_item('&Project.&Build\ Project', '', ':FortranProjectBuild<CR>')
  call s:add_menu_item('&Project.Generate\ &Tags', s:c_tags, ':FortranTags<CR>')
  call s:add_menu_item('&Project.Find\ &Module', s:c_find_mod, ':FortranFindModule<CR>')
  call s:add_menu_item('&Project.sep_proj', '', '<Nop>')
  call s:add_menu_item('&Project.&Make', s:c_make, ':FortranMake<CR>')
  call s:add_menu_item('&Project.Make\ &Properties', s:c_prop, ':FortranMakeArgs<CR>')
  call s:add_menu_item('&Project.Generate\ &Autotools\ Project', s:c_proj, ':FortranMakeProj<CR>')

  " Direct entries
  execute 'anoremenu ' . s:root . '.--sep_top-- <Nop>'
  call s:add_menu_item('&Format\ Buffer', '', ':FortranFormat<CR>')
  call s:add_menu_item('&Help', 'VimF90\ Help', ':help vimf90.txt<CR>')

  " Undo ftplugin
  let s:undo_menu = 'silent! aunmenu ' . s:root
  let b:undo_ftplugin = (exists('b:undo_ftplugin') ? b:undo_ftplugin . ' | ' : '') . s:undo_menu
endif

let &cpo = s:save_cpo
unlet s:save_cpo
