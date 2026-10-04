"########################################################################
" test_toc.vim — Native Table of Contents / Outline sidebar (:FortranToc)
"########################################################################

function! Test_toc_scans_modules_and_subprograms() abort
  let l:dir = Vf90Fixture('toc')
  let l:src = [
        \ 'module math_mod',
        \ '  implicit none',
        \ '  type :: point',
        \ '    real :: x, y',
        \ '  end type point',
        \ '  interface add',
        \ '    module procedure add_points',
        \ '  end interface',
        \ 'contains',
        \ '  pure subroutine add_points(a, b)',
        \ '    type(point), intent(in) :: a, b',
        \ '  end subroutine add_points',
        \ '  real(8) function distance(p)',
        \ '    type(point), intent(in) :: p',
        \ '  end function distance',
        \ 'end module math_mod',
        \ ]
  let l:buf = Vf90OpenScratch(l:dir . '/math.f90', l:src)
  setlocal filetype=fortran
  call toc#show()

  let l:toc_win = 0
  for l:w in range(1, winnr('$'))
    if getbufvar(winbufnr(l:w), '&filetype') ==# 'fortran_toc'
      let l:toc_win = l:w
      break
    endif
  endfor

  call assert_true(l:toc_win > 0, 'TOC window should be open')
  let l:toc_lines = getbufline(winbufnr(l:toc_win), 1, '$')

  call assert_match('\[MOD\] math_mod', join(l:toc_lines, "\n"))
  call assert_match('\[TYP\] point', join(l:toc_lines, "\n"))
  call assert_match('\[INT\] add', join(l:toc_lines, "\n"))
  call assert_match('\[SUB\] add_points', join(l:toc_lines, "\n"))
  call assert_match('\[FUN\] distance', join(l:toc_lines, "\n"))

  call toc#close()
  call assert_equal(0, s:is_toc_open())
endfunction

function! Test_toc_scans_fixed_form() abort
  let l:dir = Vf90Fixture('toc_fixed')
  let l:src = [
        \ 'C     Sample fixed form file',
        \ '      PROGRAM MAIN',
        \ '      CALL SUB1',
        \ '      END',
        \ '      SUBROUTINE SUB1',
        \ '      RETURN',
        \ '      END',
        \ ]
  let l:buf = Vf90OpenScratch(l:dir . '/sample.f', l:src)
  setlocal filetype=fortran
  call toc#show()

  let l:toc_win = 0
  for l:w in range(1, winnr('$'))
    if getbufvar(winbufnr(l:w), '&filetype') ==# 'fortran_toc'
      let l:toc_win = l:w
      break
    endif
  endfor

  call assert_true(l:toc_win > 0, 'TOC window should open for fixed form')
  let l:toc_lines = getbufline(winbufnr(l:toc_win), 1, '$')

  call assert_match('\[PRG\] MAIN', join(l:toc_lines, "\n"))
  call assert_match('\[SUB\] SUB1', join(l:toc_lines, "\n"))

  call toc#close()
endfunction

function! Test_toc_toggle_command() abort
  let l:dir = Vf90Fixture('toc_toggle')
  call Vf90OpenScratch(l:dir . '/a.f90', ['module a', 'end module a'])
  setlocal filetype=fortran

  execute 'FortranToc'
  call assert_true(s:is_toc_open(), 'FortranToc should open TOC')

  wincmd p
  execute 'FortranToc'
  call assert_false(s:is_toc_open(), 'FortranToc should close TOC when open')
endfunction

function! Test_toc_jump_moves_cursor() abort
  let l:dir = Vf90Fixture('toc_jump')
  let l:src = [
        \ 'module jump_mod',
        \ 'contains',
        \ '  subroutine first()',
        \ '  end subroutine',
        \ '  subroutine target_sub()',
        \ '  end subroutine',
        \ 'end module',
        \ ]
  let l:buf = Vf90OpenScratch(l:dir . '/jump.f90', l:src)
  setlocal filetype=fortran
  call toc#show()

  " Go to line 3 in TOC (target_sub)
  call cursor(3, 1)
  call toc#jump()

  " Verify source window is active and at line 5
  call assert_equal('jump.f90', expand('%:t'))
  call assert_equal(5, line('.'))

  call toc#close()
endfunction

function! s:is_toc_open() abort
  for l:w in range(1, winnr('$'))
    if getbufvar(winbufnr(l:w), '&filetype') ==# 'fortran_toc'
      return 1
    endif
  endfor
  return 0
endfunction

" ---------------------------------------------------------------------------
" Regressions
" ---------------------------------------------------------------------------

" The outline lines for the given source, as the sidebar shows them.
function! s:outline(name, lines) abort
  let l:dir = Vf90Fixture('toc_regress')
  call Vf90OpenScratch(l:dir . '/' . a:name, a:lines)
  call toc#show()
  let l:out = []
  for l:w in range(1, winnr('$'))
    if getbufvar(winbufnr(l:w), '&filetype') ==# 'fortran_toc'
      let l:out = getbufline(winbufnr(l:w), 1, '$')
    endif
  endfor
  call toc#close()
  return join(l:out, "\n")
endfunction

" `module procedure` is not a module, but a module merely named procedures_mod
" is: the keyword exclusion needs a word boundary.
function! Test_toc_module_named_like_a_keyword() abort
  let l:toc = s:outline('p.f90', [
        \ 'module procedures_mod',
        \ '  interface gen',
        \ '    module procedure impl',
        \ '  end interface gen',
        \ 'contains',
        \ '  subroutine impl()',
        \ '  end subroutine impl',
        \ 'end module procedures_mod'])
  call assert_match('\[MOD\] procedures_mod', l:toc)
  call assert_notmatch('\[MOD\] impl', l:toc, 'module procedure is not a module')
  call assert_notmatch('\[MOD\] procedure\s', l:toc, 'the keyword itself is not a module name')
endfunction

" A derived type may be declared without `::`.
function! Test_toc_type_without_double_colon() abort
  let l:toc = s:outline('t.f90', [
        \ 'module m',
        \ '  type point',
        \ '    real :: x',
        \ '  end type point',
        \ '  type, extends(point) :: point3',
        \ '    real :: z',
        \ '  end type point3',
        \ 'end module m'])
  call assert_match('\[TYP\] point ', l:toc, 'type point without ::')
  call assert_match('\[TYP\] point3', l:toc, 'type with attributes and ::')
endfunction

" Things that look like declarations but are not.
function! Test_toc_ignores_lookalikes() abort
  let l:toc = s:outline('l.f90', [
        \ 'module m',
        \ 'contains',
        \ '  subroutine s(obj)',
        \ '    class(*) :: obj',
        \ '    type(point) :: p',
        \ '    integer :: interfaces, programs',
        \ '    select type (obj)',
        \ '    type is (integer)',
        \ '    end select',
        \ '    interfaces = 1',
        \ '  end subroutine s',
        \ 'end module m'])
  call assert_notmatch('\[TYP\] is', l:toc, '`type is` is a SELECT TYPE guard')
  call assert_notmatch('\[TYP\] point', l:toc, '`type(point) ::` is a variable')
  call assert_notmatch('\[INT\]', l:toc, '`interfaces = 1` is an assignment')
  call assert_notmatch('\[PRG\]', l:toc)
  call assert_match('\[SUB\] s ', l:toc)
endfunction

" Function prefixes in any order, including a type spec after the modifiers,
" nested parentheses, and the INTEGER*4 form.
function! Test_toc_typed_function_forms() abort
  let l:toc = s:outline('f.f90', [
        \ 'module m',
        \ 'contains',
        \ '  real(kind(1.0d0)) function a(x)',
        \ '  end function a',
        \ '  pure integer function b(x)',
        \ '  end function b',
        \ '  integer pure function c(x)',
        \ '  end function c',
        \ '  subroutine d() bind(c)',
        \ '  end subroutine d',
        \ 'end module m'])
  for l:name in ['a', 'b', 'c']
    call assert_match('\[FUN\] ' . l:name . ' ', l:toc, 'function ' . l:name)
  endfor
  call assert_match('\[SUB\] d ', l:toc, 'subroutine with bind(c)')
endfunction

" A fixed-form continuation line carries on the statement above; column 6 is
" what marks it, not the text that follows.
function! Test_toc_fixed_form_continuation_and_labels() abort
  let l:toc = s:outline('legacy.f', [
        \ '      SUBROUTINE ONE(A,',
        \ '     &  B)',
        \ '      REAL A, B',
        \ '      END',
        \ 'C     SUBROUTINE COMMENTED',
        \ '      INTEGER*4 FUNCTION TWO(N)',
        \ '      TWO = N',
        \ '      END',
        \ '      BLOCK DATA INIT',
        \ '      END'])
  call assert_match('\[SUB\] ONE', l:toc)
  call assert_match('\[FUN\] TWO', l:toc, 'INTEGER*4 FUNCTION')
  call assert_match('\[BLK\] INIT', l:toc)
  call assert_notmatch('COMMENTED', l:toc, 'a C comment is not a declaration')
endfunction

" A whole-project outline must not load files or add them to the buffer list.
function! Test_toc_project_scan_leaves_buffer_list_alone() abort
  let l:dir = Vf90Fixture('toc_project')
  call Vf90Write(l:dir . '/fpm.toml', ['name = "demo"'])
  call Vf90Write(l:dir . '/src/b.f90', ['module b_mod', 'end module b_mod'])
  call Vf90Write(l:dir . '/src/deep/c.f90', ['module c_mod', 'end module c_mod'])
  call Vf90Write(l:dir . '/build/gfortran_ABCDEF0123456789/copy.f90',
        \ ['module stale_copy', 'end module stale_copy'])
  call Vf90OpenScratch(l:dir . '/src/a.f90', ['module a_mod', 'end module a_mod'])
  let l:before = len(getbufinfo({'buflisted': 1}))

  call toc#show('!')
  let l:toc = ''
  for l:w in range(1, winnr('$'))
    if getbufvar(winbufnr(l:w), '&filetype') ==# 'fortran_toc'
      let l:toc = join(getbufline(winbufnr(l:w), 1, '$'), "\n")
    endif
  endfor

  call assert_equal(l:before, len(getbufinfo({'buflisted': 1})),
        \ 'the project scan added files to the buffer list')
  call assert_equal(0, bufexists(l:dir . '/src/b.f90'), 'an unopened file was loaded')
  for l:mod in ['a_mod', 'b_mod', 'c_mod']
    call assert_match(l:mod, l:toc)
  endfor
  call assert_notmatch('stale_copy', l:toc, 'build/ must be skipped')
  call toc#close()
endfunction

" Jumping to a file that has never been opened opens it at the declaration.
function! Test_toc_project_jump_opens_unloaded_file() abort
  let l:dir = Vf90Fixture('toc_project_jump')
  call Vf90Write(l:dir . '/fpm.toml', ['name = "demo"'])
  call Vf90Write(l:dir . '/src/z.f90', ['! header', '! header', 'module z_mod', 'end module z_mod'])
  call Vf90OpenScratch(l:dir . '/src/a.f90', ['module a_mod', 'end module a_mod'])

  call toc#show('!')
  call assert_notequal(0, search('z_mod', 'w'), 'z_mod missing from the outline')
  call toc#jump()
  call assert_equal('z.f90', expand('%:t'))
  call assert_equal(3, line('.'))
  call assert_notequal('fortran_toc', &filetype, 'the jump stayed in the outline')
  call toc#close()
endfunction

" Unsaved edits in an open buffer are what the outline should show.
function! Test_toc_project_scan_sees_unsaved_edits() abort
  let l:dir = Vf90Fixture('toc_unsaved')
  call Vf90Write(l:dir . '/fpm.toml', ['name = "demo"'])
  call Vf90OpenScratch(l:dir . '/src/a.f90', ['module a_mod', 'end module a_mod'])
  call setline(1, 'module renamed_mod')
  call toc#show('!')
  let l:toc = ''
  for l:w in range(1, winnr('$'))
    if getbufvar(winbufnr(l:w), '&filetype') ==# 'fortran_toc'
      let l:toc = join(getbufline(winbufnr(l:w), 1, '$'), "\n")
    endif
  endfor
  call assert_match('renamed_mod', l:toc)
  call toc#close()
  setlocal nomodified
endfunction

" A project directory whose name contains a space.
function! Test_toc_project_path_with_space() abort
  let l:dir = Vf90Mkdir(Vf90Fixture('toc_space') . '/my project')
  call Vf90Write(l:dir . '/fpm.toml', ['name = "demo"'])
  call Vf90Write(l:dir . '/src/b.f90', ['module spaced_mod', 'end module spaced_mod'])
  call Vf90OpenScratch(l:dir . '/src/a.f90', ['module a_mod', 'end module a_mod'])
  call toc#show('!')
  let l:toc = ''
  for l:w in range(1, winnr('$'))
    if getbufvar(winbufnr(l:w), '&filetype') ==# 'fortran_toc'
      let l:toc = join(getbufline(winbufnr(l:w), 1, '$'), "\n")
    endif
  endfor
  call assert_match('spaced_mod', l:toc)
  call toc#close()
endfunction
