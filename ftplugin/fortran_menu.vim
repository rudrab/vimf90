if !exists('g:Fortran_menumode')
    let g:Fortran_menumode = 1
endif

if has('gui_running') && has('menu')
    if g:Fortran_menumode == 1
        let s:menu_root = 'Fortran'
    elseif g:Fortran_menumode == 2
        let s:menu_root = 'Fortran'
    endif

    if g:Fortran_menumode == 1 || g:Fortran_menumode == 2
        for s:menu_textcmd in [
                    \ '&Compile<tab>:SCCompile '.
                    \ ':SCCompile<cr>',
                    \
                    \ 'Compile\ and\ &Run<tab>:SCCompileRun '.
                    \ ':SCCompileRun<cr>',
                    \
                    \ 'Compile\ and\ Run &Asynchronously'.
                    \ '<tab>:SCCompileRunAsync'.
                    \ ':SCCompileRunAsync<cr>',
                    \
                    \ 'C&hoose\ Compiler<tab>:SCChooseCompiler '.
                    \ ':SCChooseCompiler<cr>',
                    \
                    \ '&View\ Result<tab>:SCViewResult '.
                    \ ':SCViewResult<cr>',
                    \
                    \ 'V&iew\ Result\ of\ Asynchronous\ Running'.
                    \ '<tab>:SCViewResultAsync '.
                    \ ':SCViewResultAsync<cr>',
                    \
                    \ '&Terminate\ the\ Background\ Asynchronous\ Process'.
                    \ '<tab>:SCTerminateAsync '.
                    \ ':SCTerminateAsync<cr>'
                    \ ]

            for s:menu_type in ['nnoremenu', 'inoremenu', 'vnoremenu']
                exec s:menu_type.' '.s:menu_root.'.'.s:menu_textcmd
            endfor
        endfor

        unlet! s:menu_root
        unlet! s:menu_type
        unlet! s:menu_textcmd
    endif
endif
