"#:imap `prg ! Program <C-r>=expand('%:r')<CR><CR>! Author     :<C-R>=$USER <CR><CR>! Date      :<C-R>=strftime("%d/%m/%Y")<CR><CR>Program  <C-r>=expand('%:r')<CR><CR>Implicit None<CR><++Start Here++><CR>End Program <C-r>=expand('%:r')<CR><CR><esc>gg=G<C-j>
"#:imap `mod ! Module <C-r>=expand('%:r')<CR><CR>Module  <C-r>=expand('%:r')<CR><CR>Implicit None<CR><++Start Here++><CR>End Module <C-r>=expand('%:r')<CR><CR><esc>gg=G<C-j>

:imap `prg prg<S-Tab><Esc>gg=G<C-j>
:imap `mod mod<S-Tab><Esc>gg=G<C-j>
:imap `sub sub<S-Tab><Esc>gg=G<C-j>
:imap `fun fun<S-Tab><Esc>gg=G<C-j>
