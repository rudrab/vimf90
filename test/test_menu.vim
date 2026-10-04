"########################################################################
" test_menu.vim — the GUI menu.
"
" Terminal Vim is built with +menu even though it never draws one, so every
" item can be installed for real here. That matters: this menu shipped with two
" labels ending in "..." which Vim read as empty path components and rejected
" with E792, and no amount of reading the source made that obvious.
"########################################################################

function! s:need_menu() abort
  if !has('menu')
    call Vf90Skip('this build has no menu support')
  endif
endfunction

function! s:open_fortran_buffer() abort
  let l:dir = Vf90Fixture('menu')
  call Vf90OpenScratch(l:dir . '/a.f90', ['program a', 'end program a'])
  setlocal filetype=fortran
endfunction

" The failure this file exists for: every item must actually install.
function! Test_every_menu_item_installs() abort
  call s:need_menu()
  call s:open_fortran_buffer()
  let l:root = 'Vf90TestMenu'
  for l:item in fortran_menu#items()
    let l:mpath = fortran_menu#path(l:root, l:item)
    try
      execute 'anoremenu <script> ' . l:mpath . ' ' . l:item[2]
      execute 'inoremenu <script> ' . l:mpath . ' <C-C>' . l:item[2]
    catch
      call assert_report('menu item ' . string(l:item[0]) . ' failed: ' . v:exception)
    endtry
  endfor
  silent! execute 'aunmenu ' . l:root
endfunction

" The real install path, as the ftplugin calls it. Only the guard in the
" ftplugin needs a GUI; the menu engine itself is present in terminal builds,
" and it is the engine that rejects a malformed path.
function! Test_setup_installs_the_whole_menu() abort
  call s:need_menu()
  call s:open_fortran_buffer()
  let g:fortran_menu_name = 'Vf90SetupTest'
  try
    call fortran_menu#setup()
    let l:installed = execute('menu Vf90SetupTest')
    call assert_match('Compile', l:installed, 'the Compile submenu is missing')
    call assert_match('FPM', l:installed, 'the FPM submenu is missing')
    call assert_match('Inspect', l:installed, 'the item that used to fail is missing')
    call assert_match('Dependency', l:installed, 'the other failing item is missing')
    call assert_match('aunmenu Vf90SetupTest', b:undo_ftplugin, 'no teardown registered')
  finally
    silent! aunmenu Vf90SetupTest
    unlet g:fortran_menu_name
  endtry
endfunction

" A dot separates path components, so a dot inside a label has to be escaped.
function! Test_menu_labels_escape_dots() abort
  for l:item in fortran_menu#items()
    for l:component in split(l:item[0], '\\\@<!\.')
      call assert_notequal('', l:component,
            \ 'empty menu path component in ' . string(l:item[0])
            \ . ' -- an unescaped dot inside a label')
    endfor
  endfor
endfunction

" Spaces separate the menu path from the command, so they must be escaped too.
function! Test_menu_labels_escape_spaces() abort
  for l:item in fortran_menu#items()
    call assert_notmatch('\\\@<! ', l:item[0],
          \ 'unescaped space in menu path ' . string(l:item[0]))
  endfor
endfunction

" A separator is an item whose name starts and ends with a hyphen. Anything
" else named "sep" is drawn as an ordinary entry, which is what used to happen.
function! Test_menu_separators_are_named_as_separators() abort
  for l:item in fortran_menu#items()
    if l:item[2] ==# '<Nop>'
      let l:leaf = split(l:item[0], '\\\@<!\.')[-1]
      call assert_match('^-.*-$', l:leaf,
            \ 'separator ' . string(l:item[0]) . ' is not named -like-this-')
    endif
  endfor
endfunction

" Every menu entry should invoke a command that exists.
function! Test_menu_commands_exist() abort
  call s:open_fortran_buffer()
  for l:item in fortran_menu#items()
    let l:cmd = matchstr(l:item[2], '^:\zs[A-Za-z]\+')
    if !empty(l:cmd)
      call assert_notequal(0, exists(':' . l:cmd),
            \ 'menu entry ' . string(l:item[0]) . ' calls :' . l:cmd . ', which does not exist')
    endif
  endfor
endfunction

function! Test_menu_root_defaults_to_fortran() abort
  call s:open_fortran_buffer()
  call assert_equal('&Fortran', fortran_menu#root())
endfunction

function! Test_menu_root_follows_dialect_when_asked() abort
  let l:dir = Vf90Fixture('menu')
  call Vf90OpenScratch(l:dir . '/a.f90', ['program a', 'end program a'])
  let g:fortran_menu_dynamic_dialect = 1
  try
    call assert_equal('&Fortran\ 90', fortran_menu#root())
  finally
    unlet g:fortran_menu_dynamic_dialect
  endtry
endfunction

function! Test_menu_root_can_be_overridden() abort
  let g:fortran_menu_name = '&MyFortran'
  try
    call assert_equal('&MyFortran', fortran_menu#root())
  finally
    unlet g:fortran_menu_name
  endtry
endfunction

" The shortcut column is separated from the label by <Tab>.
function! Test_menu_path_carries_the_shortcut() abort
  let l:path = fortran_menu#path('&Fortran', ['&Compile.&Compile', '\cc', ':FortranCompile<CR>'])
  call assert_equal('&Fortran.&Compile.&Compile<Tab>\\cc', l:path)
endfunction

function! Test_menu_path_omits_an_empty_shortcut() abort
  let l:path = fortran_menu#path('&Fortran', ['&Compile.&Compile', '', ':FortranCompile<CR>'])
  call assert_equal('&Fortran.&Compile.&Compile', l:path)
endfunction

function! Test_menu_shortcut_expands_the_leader() abort
  call s:open_fortran_buffer()
  let g:fortran_leader = ','
  let b:fortran_compile = '<leader>cc'
  try
    let l:items = filter(fortran_menu#items(), 'v:val[0] ==# "&Compile.&Compile"')
    call assert_equal(',cc', l:items[0][1], '<leader> should be rendered')
  finally
    unlet b:fortran_compile
  endtry
endfunction
