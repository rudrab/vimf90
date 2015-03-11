
if !exists('g:Fortran_menumode')
  let g:Fortran_menumode = 1
endif

if has('gui_running') && has('menu')
  let s:menu_root = 'Fortran'

  if g:Fortran_menumode == 1
    an  Fortran&90.&Compile.                     :make
    an  &Fortran90.--sep0--                      <Nop>
    an  &Fortran90.&Blocks.&Program<Tab>`prg     `prg
    an  &Fortran90.&Blocks.&Module<Tab>`mod      `mod
    an  &Fortran90.&Blocks.&Subroutine<Tab>`sub  `sub
    an  &Fortran90.&Blocks.&Function<Tab>`fun    `fun
    an  &Fortran90.--sep1--                      <Nop>
    an  &Fortran90.&Help<Tab>VimF90\ Help        :h vimf90.txt<CR>
  endif
endif
