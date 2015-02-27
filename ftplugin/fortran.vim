autocmd Bufwritepre,filewritepre *.f90 silent! exe "1," . 10 . "g/Last Modified :.*/s/Last Modified :.*/Last Modified : " .strftime("%c")
