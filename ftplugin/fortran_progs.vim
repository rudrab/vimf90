"#:imap `prg ! Program <C-r>=expand('%:r')<CR><CR>! Author     :<C-R>=$USER <CR><CR>! Date      :<C-R>=strftime("%d/%m/%Y")<CR><CR>Program  <C-r>=expand('%:r')<CR><CR>Implicit None<CR><++Start Here++><CR>End Program <C-r>=expand('%:r')<CR><CR><esc>gg=G<C-j>
"#:imap `mod ! Module <C-r>=expand('%:r')<CR><CR>Module  <C-r>=expand('%:r')<CR><CR>Implicit None<CR><++Start Here++><CR>End Module <C-r>=expand('%:r')<CR><CR><esc>gg=G<C-j>

:execute 'imap `prg prg' . g:UltiSnipsExpandTrigger . '<Esc>gg=G<C-j>'
:execute 'imap `mod mod' . g:UltiSnipsExpandTrigger . '<Esc>gg=G<C-j>'
:execute 'imap `sub sub' . g:UltiSnipsExpandTrigger . '<Esc>gg=G<C-j>'
:execute 'imap `fun fun' . g:UltiSnipsExpandTrigger . '<Esc>gg=G<C-j>'
