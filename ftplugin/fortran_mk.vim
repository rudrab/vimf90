"########################################################################
" Filename:      ftplugin/fortran_mk.vim
" Copyright:     Copyright (C) 2019-2026 Rudra Banerjee
" License:       GPLv3
" Description:   Fortran build/run commands, presets, doc generation,
"                text objects, motions, and plug mappings
"########################################################################

let s:save_cpo = &cpo
set cpo&vim

" Initialize Tagbar integration if available
call fortran_tagbar#setup()

" Plug mappings - Core Actions
nnoremap <buffer> <silent> <Plug>(vimf90-compile)        :call makes#Fcompile()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-exe)            :call makes#Fexe()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-run)            :call makes#Frun()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-cla)            :call makes#Cla()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-dbg)            :call makes#Fdbg()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-make)           :call makes#MakeRun()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-makeprop)       :call makes#MakeCla()<CR>

" Plug mappings - fpm
nnoremap <buffer> <silent> <Plug>(vimf90-fpm-build)         :call fpm#build()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-fpm-run)           :call fpm#run()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-fpm-test)          :call fpm#test()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-fpm-test-current)  :call fpm#test_current()<CR>

" Plug mappings - Multi-file Project
nnoremap <buffer> <silent> <Plug>(vimf90-project-build)  :call project#build()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-tags)           :call project#generate_tags()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-find-module)    :call project#find_module('')<CR>

" Plug mappings - Documentation & FORD
nnoremap <buffer> <silent> <Plug>(vimf90-doc)            :call doc#generate('')<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-ford-build)     :call doc#ford_build()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-ford-preview)   :call doc#ford_preview()<CR>

" Plug mappings - Profiles & Presets
nnoremap <buffer> <silent> <Plug>(vimf90-profile)        :call profiles#set_profile('')<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-openmp)         :call profiles#toggle_openmp()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-mpi)            :call profiles#toggle_mpi()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-gpu-toggle)     :call hpc#toggle_gpu('')<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-mpi-run)        :call hpc#mpi_run()<CR>

" Plug mappings - Scientific Debugging & Array Inspector
nnoremap <buffer> <silent> <Plug>(vimf90-inspect-array)     :call dap#inspect_array()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-breakpoint-toggle) :call dap#toggle_breakpoint()<CR>

" Plug mappings - Interactive REPL & Scratchpad
nnoremap <buffer> <silent> <Plug>(vimf90-repl-toggle)       :call repl#toggle()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-repl-open)         :call repl#open()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-repl-send-line)    :<C-U>call repl#send_line(v:count1)<CR>
xnoremap <buffer> <silent> <Plug>(vimf90-repl-send-visual)  :call repl#send_visual()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-repl-send-subprog) :call repl#send_subprogram()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-repl-send-buffer)  :call repl#send_buffer()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-repl-restart)      :call repl#restart()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-scratch-open)      :call scratch#open()<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-scratch-run)       :call scratch#run()<CR>

" Plug mappings - Text Objects
xnoremap <buffer> <silent> <Plug>(vimf90-textobj-func-a)  :<C-U>call textobj#select('func', 0)<CR>
xnoremap <buffer> <silent> <Plug>(vimf90-textobj-func-i)  :<C-U>call textobj#select('func', 1)<CR>
onoremap <buffer> <silent> <Plug>(vimf90-textobj-func-a)  :<C-U>call textobj#select('func', 0)<CR>
onoremap <buffer> <silent> <Plug>(vimf90-textobj-func-i)  :<C-U>call textobj#select('func', 1)<CR>

xnoremap <buffer> <silent> <Plug>(vimf90-textobj-mod-a)   :<C-U>call textobj#select('module', 0)<CR>
xnoremap <buffer> <silent> <Plug>(vimf90-textobj-mod-i)   :<C-U>call textobj#select('module', 1)<CR>
onoremap <buffer> <silent> <Plug>(vimf90-textobj-mod-a)   :<C-U>call textobj#select('module', 0)<CR>
onoremap <buffer> <silent> <Plug>(vimf90-textobj-mod-i)   :<C-U>call textobj#select('module', 1)<CR>

xnoremap <buffer> <silent> <Plug>(vimf90-textobj-type-a)  :<C-U>call textobj#select('type', 0)<CR>
xnoremap <buffer> <silent> <Plug>(vimf90-textobj-type-i)  :<C-U>call textobj#select('type', 1)<CR>
onoremap <buffer> <silent> <Plug>(vimf90-textobj-type-a)  :<C-U>call textobj#select('type', 0)<CR>
onoremap <buffer> <silent> <Plug>(vimf90-textobj-type-i)  :<C-U>call textobj#select('type', 1)<CR>

xnoremap <buffer> <silent> <Plug>(vimf90-textobj-do-a)    :<C-U>call textobj#select('do', 0)<CR>
xnoremap <buffer> <silent> <Plug>(vimf90-textobj-do-i)    :<C-U>call textobj#select('do', 1)<CR>
onoremap <buffer> <silent> <Plug>(vimf90-textobj-do-a)    :<C-U>call textobj#select('do', 0)<CR>
onoremap <buffer> <silent> <Plug>(vimf90-textobj-do-i)    :<C-U>call textobj#select('do', 1)<CR>

xnoremap <buffer> <silent> <Plug>(vimf90-textobj-block-a) :<C-U>call textobj#select('block', 0)<CR>
xnoremap <buffer> <silent> <Plug>(vimf90-textobj-block-i) :<C-U>call textobj#select('block', 1)<CR>
onoremap <buffer> <silent> <Plug>(vimf90-textobj-block-a) :<C-U>call textobj#select('block', 0)<CR>
onoremap <buffer> <silent> <Plug>(vimf90-textobj-block-i) :<C-U>call textobj#select('block', 1)<CR>

" Plug mappings - Structural Motions
nnoremap <buffer> <silent> <Plug>(vimf90-motion-next-start) :<C-U>call textobj#jump('subprog', 1, 0)<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-motion-prev-start) :<C-U>call textobj#jump('subprog', 0, 0)<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-motion-next-end)   :<C-U>call textobj#jump('subprog', 1, 1)<CR>
nnoremap <buffer> <silent> <Plug>(vimf90-motion-prev-end)   :<C-U>call textobj#jump('subprog', 0, 1)<CR>

xnoremap <buffer> <silent> <Plug>(vimf90-motion-next-start) :<C-U>call textobj#jump('subprog', 1, 0)<CR>m'gv``
xnoremap <buffer> <silent> <Plug>(vimf90-motion-prev-start) :<C-U>call textobj#jump('subprog', 0, 0)<CR>m'gv``
xnoremap <buffer> <silent> <Plug>(vimf90-motion-next-end)   :<C-U>call textobj#jump('subprog', 1, 1)<CR>m'gv``
xnoremap <buffer> <silent> <Plug>(vimf90-motion-prev-end)   :<C-U>call textobj#jump('subprog', 0, 1)<CR>m'gv``

onoremap <buffer> <silent> <Plug>(vimf90-motion-next-start) :<C-U>call textobj#jump('subprog', 1, 0)<CR>
onoremap <buffer> <silent> <Plug>(vimf90-motion-prev-start) :<C-U>call textobj#jump('subprog', 0, 0)<CR>
onoremap <buffer> <silent> <Plug>(vimf90-motion-next-end)   :<C-U>call textobj#jump('subprog', 1, 1)<CR>
onoremap <buffer> <silent> <Plug>(vimf90-motion-prev-end)   :<C-U>call textobj#jump('subprog', 0, 1)<CR>

" User commands - Core
command! -buffer -bar -nargs=* FortranCompile     call makes#Fcompile(<f-args>)
command! -buffer -bar -nargs=* FortranExe         call makes#Fexe(<f-args>)
command! -buffer -bar          FortranRun         call makes#Frun()
command! -buffer -bar          FortranArgs        call makes#Cla()
command! -buffer -bar          FortranDebug       call makes#Fdbg()
command! -buffer -bar          FortranMake        call makes#MakeRun()
command! -buffer -bar          FortranMakeArgs    call makes#MakeCla()

" User commands - Documentation & FORD
command! -buffer -bar -nargs=? FortranDoc  call doc#generate(<q-args>)
command! -buffer -bar          FordBuild   call doc#ford_build()
command! -buffer -bar          FordPreview call doc#ford_preview()

" User commands - Profiles, Compilers & Presets
command! -buffer -bar -nargs=? -complete=customlist,profiles#complete_profile  FortranProfile  call profiles#set_profile(<q-args>)
command! -buffer -bar -nargs=? -complete=customlist,profiles#complete_compiler FortranCompiler call profiles#set_compiler(<q-args>)
command! -buffer -bar -nargs=? -complete=customlist,profiles#complete_toggle   FortranOpenMP   call profiles#toggle_openmp(<q-args>)
command! -buffer -bar -nargs=? -complete=customlist,profiles#complete_toggle   FortranMPI      call profiles#toggle_mpi(<q-args>)
command! -buffer -bar -nargs=? -complete=customlist,hpc#complete_gpu           FortranGPU      call hpc#toggle_gpu(<q-args>)
command! -buffer -bar -nargs=*                                                 FortranMPIRun   call hpc#mpi_run(<f-args>)

" User commands - Scientific Debugging & DAP
command! -buffer -bar -nargs=* FortranInspectArray    call dap#inspect_array(<f-args>)
command! -buffer -bar          FortranBreakpointToggle call dap#toggle_breakpoint()
command! -buffer -bar -nargs=? FortranTermdebug       call dap#termdebug(<q-args>)
command! -buffer -bar          FortranDapStart        call dap#start()

" User commands - Fortran Package Manager (fpm)
command! -buffer -nargs=* -complete=customlist,fpm#complete                 FortranFpm            call fpm#command(<q-args>)
command! -buffer -bar -nargs=*                                              FortranFpmBuild       call fpm#build(<q-args>)
command! -buffer -bar -nargs=* -complete=customlist,fpm#complete_app_targets FortranFpmRun        call fpm#run(<q-args>)
command! -buffer -bar -nargs=* -complete=customlist,fpm#complete_test_targets FortranFpmTest       call fpm#test(<q-args>)
command! -buffer -bar                                                       FortranFpmTestCurrent call fpm#test_current()
command! -buffer -bar -nargs=?                                              FortranFpmNew         call fpm#new(<q-args>)
command! -buffer -bar -nargs=1 -complete=customlist,fpm#complete_known_deps FortranFpmAdd         call fpm#add_dependency(<q-args>)

" User commands - Multi-file Project Tools
command! -buffer -bar -nargs=* FortranProjectBuild call project#build(<q-args>)
command! -buffer -bar          FortranProjectRoot  echo project#find_root()
command! -buffer -bar          FortranTags         call project#generate_tags()
command! -buffer -bar -nargs=? FortranFindModule   call project#find_module(<q-args>)

" User commands - Interactive REPL & Scratchpad
command! -buffer -bar -nargs=?                                                  FortranReplOpen          call repl#open(<q-args>)
command! -buffer -bar                                                           FortranReplToggle        call repl#toggle()
command! -buffer -bar -range                                                    FortranReplSend          <line1>,<line2>call repl#send_visual()
command! -buffer -bar                                                           FortranReplSendSubprogram call repl#send_subprogram()
command! -buffer -bar                                                           FortranReplSendBuffer    call repl#send_buffer()
command! -buffer -bar                                                           FortranReplRestart       call repl#restart()
command! -buffer -bar -nargs=? -complete=customlist,scratch#complete_template   FortranScratch           call scratch#open(<q-args>)
command! -buffer -bar                                                           FortranScratchRun        call scratch#run()

" Legacy helper function wrappers for backwards compatibility
function! Compile() abort
  return makes#Fcompile()
endfunction

function! Gexe() abort
  return makes#Fexe()
endfunction

function! Run() abort
  return makes#Frun()
endfunction

function! CLArgs() abort
  return makes#Cla()
endfunction

function! Debug() abort
  return makes#Fdbg()
endfunction

function! Make() abort
  return makes#MakeRun()
endfunction

function! MakeProperties() abort
  return makes#MakeCla()
endfunction

" Undo ftplugin
let s:cmds = [
      \ 'FortranCompile', 'FortranExe', 'FortranRun', 'FortranArgs', 'FortranDebug',
      \ 'FortranMake', 'FortranMakeArgs',
      \ 'FortranDoc', 'FordBuild', 'FordPreview',
      \ 'FortranProfile', 'FortranCompiler', 'FortranOpenMP', 'FortranMPI',
      \ 'FortranGPU', 'FortranMPIRun',
      \ 'FortranInspectArray', 'FortranBreakpointToggle', 'FortranTermdebug', 'FortranDapStart',
      \ 'FortranFpm', 'FortranFpmBuild', 'FortranFpmRun', 'FortranFpmTest',
      \ 'FortranFpmTestCurrent', 'FortranFpmNew', 'FortranFpmAdd',
      \ 'FortranProjectBuild', 'FortranProjectRoot', 'FortranTags', 'FortranFindModule',
      \ 'FortranReplOpen', 'FortranReplToggle', 'FortranReplSend',
      \ 'FortranReplSendSubprogram', 'FortranReplSendBuffer', 'FortranReplRestart',
      \ 'FortranScratch', 'FortranScratchRun'
      \ ]
let s:delcmds = join(map(s:cmds, '"delcommand " . v:val'), ' | ')

let s:plugs = [
      \ '<Plug>(vimf90-compile)', '<Plug>(vimf90-exe)', '<Plug>(vimf90-run)',
      \ '<Plug>(vimf90-cla)', '<Plug>(vimf90-dbg)', '<Plug>(vimf90-make)',
      \ '<Plug>(vimf90-makeprop)',
      \ '<Plug>(vimf90-fpm-build)', '<Plug>(vimf90-fpm-run)', '<Plug>(vimf90-fpm-test)',
      \ '<Plug>(vimf90-fpm-test-current)',
      \ '<Plug>(vimf90-project-build)', '<Plug>(vimf90-tags)', '<Plug>(vimf90-find-module)',
      \ '<Plug>(vimf90-doc)', '<Plug>(vimf90-ford-build)', '<Plug>(vimf90-ford-preview)',
      \ '<Plug>(vimf90-profile)', '<Plug>(vimf90-openmp)', '<Plug>(vimf90-mpi)',
      \ '<Plug>(vimf90-gpu-toggle)', '<Plug>(vimf90-mpi-run)',
      \ '<Plug>(vimf90-inspect-array)', '<Plug>(vimf90-breakpoint-toggle)',
      \ '<Plug>(vimf90-repl-toggle)', '<Plug>(vimf90-repl-open)', '<Plug>(vimf90-repl-send-line)',
      \ '<Plug>(vimf90-repl-send-visual)', '<Plug>(vimf90-repl-send-subprog)',
      \ '<Plug>(vimf90-repl-send-buffer)', '<Plug>(vimf90-repl-restart)',
      \ '<Plug>(vimf90-scratch-open)', '<Plug>(vimf90-scratch-run)',
      \ '<Plug>(vimf90-textobj-func-a)', '<Plug>(vimf90-textobj-func-i)',
      \ '<Plug>(vimf90-textobj-mod-a)', '<Plug>(vimf90-textobj-mod-i)',
      \ '<Plug>(vimf90-textobj-type-a)', '<Plug>(vimf90-textobj-type-i)',
      \ '<Plug>(vimf90-textobj-do-a)', '<Plug>(vimf90-textobj-do-i)',
      \ '<Plug>(vimf90-textobj-block-a)', '<Plug>(vimf90-textobj-block-i)',
      \ '<Plug>(vimf90-motion-next-start)', '<Plug>(vimf90-motion-prev-start)',
      \ '<Plug>(vimf90-motion-next-end)', '<Plug>(vimf90-motion-prev-end)'
      \ ]
let s:unplugs = join(map(s:plugs, '"silent! unmap <buffer> " . v:val'), ' | ')

let b:undo_ftplugin = (exists('b:undo_ftplugin') ? b:undo_ftplugin . ' | ' : '') . s:delcmds . ' | ' . s:unplugs

let &cpo = s:save_cpo
unlet s:save_cpo
