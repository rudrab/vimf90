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
  let s:c_comp       = s:format_shortcut(get(b:, 'fortran_compile',       '\cc'))
  let s:c_exe        = s:format_shortcut(get(b:, 'fortran_exe',           '\ce'))
  let s:c_run        = s:format_shortcut(get(b:, 'fortran_run',           '\cr'))
  let s:c_cla        = s:format_shortcut(get(b:, 'fortran_cla',           '\cl'))
  let s:c_dbg        = s:format_shortcut(get(b:, 'fortran_dbg',           '\cd'))
  let s:c_fpm_build  = s:format_shortcut(get(b:, 'fortran_fpm_build',     '\fb'))
  let s:c_fpm_run    = s:format_shortcut(get(b:, 'fortran_fpm_run',       '\fr'))
  let s:c_fpm_test   = s:format_shortcut(get(b:, 'fortran_fpm_test',      '\ft'))
  let s:c_fpm_tcur   = s:format_shortcut(get(b:, 'fortran_fpm_test_cur',  '\tc'))
  let s:c_tags       = s:format_shortcut(get(b:, 'fortran_tags',          '\tg'))
  let s:c_find_mod   = s:format_shortcut(get(b:, 'fortran_find_mod',      '\fm'))
  let s:c_doc        = s:format_shortcut(get(b:, 'fortran_doc',           '\dc'))
  let s:c_ford_bld   = s:format_shortcut(get(b:, 'fortran_ford_build_map', '\db'))
  let s:c_ford_prv   = s:format_shortcut(get(b:, 'fortran_ford_prev_map',  '\dp'))
  let s:c_prof       = s:format_shortcut(get(b:, 'fortran_profile',       '\pp'))
  let s:c_omp        = s:format_shortcut(get(b:, 'fortran_openmp',        '\po'))
  let s:c_mpi        = s:format_shortcut(get(b:, 'fortran_mpi',           '\pm'))
  let s:c_gpu        = s:format_shortcut(get(b:, 'fortran_gpu',           '\pg'))
  let s:c_mpirun     = s:format_shortcut(get(b:, 'fortran_mpirun',        '\pr'))
  let s:c_repl_tog   = s:format_shortcut(get(b:, 'fortran_repl_toggle',    '\rt'))
  let s:c_repl_snd   = s:format_shortcut(get(b:, 'fortran_repl_send',      '\rs'))
  let s:c_repl_sub   = s:format_shortcut(get(b:, 'fortran_repl_subprog',   '\rm'))
  let s:c_repl_buf   = s:format_shortcut(get(b:, 'fortran_repl_buffer',    '\rb'))
  let s:c_scrat_op   = s:format_shortcut(get(b:, 'fortran_scratch',        '\so'))
  let s:c_scrat_rn   = s:format_shortcut(get(b:, 'fortran_scratch_run',    '\sr'))
  let s:c_insp_arr   = s:format_shortcut(get(b:, 'fortran_inspect_array',  '\da'))
  let s:c_brk_tog    = s:format_shortcut(get(b:, 'fortran_break_toggle',   '\dt'))
  let s:c_make       = s:format_shortcut(get(b:, 'fortran_make',          '\mk'))
  let s:c_prop       = s:format_shortcut(get(b:, 'fortran_makeProp',      '\mp'))

  " Helper for adding menu item
  function! s:add_menu_item(path, shortcut, cmd) abort
    let l:tab = !empty(a:shortcut) ? '<Tab>' . escape(a:shortcut, " \\|\t") : ''
    let l:mpath = s:root . '.' . a:path . l:tab
    execute 'anoremenu <script> ' . l:mpath . ' ' . a:cmd
    execute 'inoremenu <script> ' . l:mpath . ' <C-C>' . a:cmd
  endfunction

  " Compile & Debug Submenu
  call s:add_menu_item('&Compile.&Compile', s:c_comp, ':FortranCompile<CR>')
  call s:add_menu_item('&Compile.Generate\ &Executable', s:c_exe, ':FortranExe<CR>')
  call s:add_menu_item('&Compile.Compile\ &and\ Run', s:c_run, ':FortranRun<CR>')
  call s:add_menu_item('&Compile.Command\ Line\ &Arguments', s:c_cla, ':FortranArgs<CR>')
  call s:add_menu_item('&Compile.sep_dbg', '', '<Nop>')
  call s:add_menu_item('&Compile.Start\ &Debugger\ (GDB/DAP)', s:c_dbg, ':FortranDebug<CR>')
  call s:add_menu_item('&Compile.Toggle\ &Breakpoint', s:c_brk_tog, ':FortranBreakpointToggle<CR>')
  call s:add_menu_item('&Compile.&Inspect\ Matrix\ Array...', s:c_insp_arr, ':FortranInspectArray<CR>')

  " Fortran Package Manager (fpm) Submenu
  call s:add_menu_item('&FPM.fpm\ &Build', s:c_fpm_build, ':FortranFpmBuild<CR>')
  call s:add_menu_item('&FPM.fpm\ &Run', s:c_fpm_run, ':FortranFpmRun<CR>')
  call s:add_menu_item('&FPM.fpm\ &Test\ All', s:c_fpm_test, ':FortranFpmTest<CR>')
  call s:add_menu_item('&FPM.fpm\ Test\ &Current\ File', s:c_fpm_tcur, ':FortranFpmTestCurrent<CR>')
  call s:add_menu_item('&FPM.sep_fpm', '', '<Nop>')
  call s:add_menu_item('&FPM.fpm\ &New\ Project', '', ':FortranFpmNew<CR>')
  call s:add_menu_item('&FPM.fpm\ &Add\ Dependency...', '', ':FortranFpmAdd ')

  " Interactive REPL & Scratchpad Submenu
  call s:add_menu_item('&Interactive.Toggle\ &LFortran\ REPL', s:c_repl_tog, ':FortranReplToggle<CR>')
  call s:add_menu_item('&Interactive.Send\ &Line\ /\ Selection', s:c_repl_snd, ':FortranReplSend<CR>')
  call s:add_menu_item('&Interactive.Send\ Enclosing\ &Subprogram', s:c_repl_sub, ':FortranReplSendSubprogram<CR>')
  call s:add_menu_item('&Interactive.Send\ Entire\ &Buffer', s:c_repl_buf, ':FortranReplSendBuffer<CR>')
  call s:add_menu_item('&Interactive.Restart\ &REPL', '', ':FortranReplRestart<CR>')
  call s:add_menu_item('&Interactive.sep_repl', '', '<Nop>')
  call s:add_menu_item('&Interactive.Open\ Scientific\ &Scratchpad', s:c_scrat_op, ':FortranScratch<CR>')
  call s:add_menu_item('&Interactive.&Run\ Scratchpad', s:c_scrat_rn, ':FortranScratchRun<CR>')

  " HPC & Supercomputing Presets Submenu
  call s:add_menu_item('&HPC.Profile:\ &Debug', s:c_prof, ':FortranProfile debug<CR>')
  call s:add_menu_item('&HPC.Profile:\ &Release', '', ':FortranProfile release<CR>')
  call s:add_menu_item('&HPC.Profile:\ &Fast\ Math', '', ':FortranProfile fast<CR>')
  call s:add_menu_item('&HPC.Profile:\ &Sanitize', '', ':FortranProfile sanitize<CR>')
  call s:add_menu_item('&HPC.sep_hpc1', '', '<Nop>')
  call s:add_menu_item('&HPC.Toggle\ &OpenMP', s:c_omp, ':FortranOpenMP<CR>')
  call s:add_menu_item('&HPC.Toggle\ &MPI\ Wrapper', s:c_mpi, ':FortranMPI<CR>')
  call s:add_menu_item('&HPC.Toggle\ &GPU\ Offloading', s:c_gpu, ':FortranGPU<CR>')
  call s:add_menu_item('&HPC.sep_hpc2', '', '<Nop>')
  call s:add_menu_item('&HPC.Run\ &MPI\ Cluster\ Job', s:c_mpirun, ':FortranMPIRun<CR>')

  " Documentation & FORD Submenu
  call s:add_menu_item('&Documentation.Generate\ &FORD\ Docstring', s:c_doc, ':FortranDoc ford<CR>')
  call s:add_menu_item('&Documentation.Generate\ &Doxygen\ Docstring', '', ':FortranDoc doxygen<CR>')
  call s:add_menu_item('&Documentation.sep_doc', '', '<Nop>')
  call s:add_menu_item('&Documentation.&Build\ Project\ FORD\ Docs', s:c_ford_bld, ':FordBuild<CR>')
  call s:add_menu_item('&Documentation.&Preview\ FORD\ Docs\ in\ Browser', s:c_ford_prv, ':FordPreview<CR>')

  " Project & Tools Submenu
  call s:add_menu_item('&Project.&Build\ Project', '', ':FortranProjectBuild<CR>')
  call s:add_menu_item('&Project.Generate\ &Tags', s:c_tags, ':FortranTags<CR>')
  call s:add_menu_item('&Project.Find\ &Module', s:c_find_mod, ':FortranFindModule<CR>')
  call s:add_menu_item('&Project.sep_proj', '', '<Nop>')
  call s:add_menu_item('&Project.&Make\ (Fallback)', s:c_make, ':FortranMake<CR>')
  call s:add_menu_item('&Project.Make\ &Properties', s:c_prop, ':FortranMakeArgs<CR>')

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
