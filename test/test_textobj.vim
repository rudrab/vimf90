"########################################################################
" test_textobj.vim — construct boundaries, motions and their edge cases.
"
" Line numbers refer to test/fixtures/freeform/typed.f90 and upper.f90.
"########################################################################

function! s:open(fixture) abort
  let l:dir = Vf90Fixture('textobj')
  call Vf90CopyFixture(a:fixture, l:dir)
  return l:dir
endfunction

function! s:bounds(file, line, type) abort
  execute 'silent edit! ' . fnameescape(a:file)
  call cursor(a:line, 1)
  return textobj#find_bounds(a:type)
endfunction

" A function statement may carry a declaration type spec, which is how most
" real Fortran functions are written.
function! Test_typed_function_declarations() abort
  let l:f = s:open('freeform') . '/typed.f90'
  call assert_equal([11, 14], s:bounds(l:f, 12, 'func'), 'real function')
  call assert_equal([16, 19], s:bounds(l:f, 17, 'func'), 'integer(kind=8) pure function')
  call assert_equal([21, 23], s:bounds(l:f, 22, 'func'), 'character(len=*) function')
  call assert_equal([30, 35], s:bounds(l:f, 31, 'func'), 'type(solver) function')
  call assert_equal([37, 39], s:bounds(l:f, 38, 'func'), 'plain subroutine')
endfunction

" real(kind(1.0d0)) has nested parentheses; the type spec must backtrack past
" the inner closing paren rather than stopping at it.
function! Test_nested_parentheses_in_type_spec() abort
  let l:f = s:open('freeform') . '/typed.f90'
  call assert_equal([25, 28], s:bounds(l:f, 26, 'func'), 'real(kind(1.0d0)) function')
endfunction

" Declarations that merely begin with a type keyword are not function starts.
function! Test_declarations_are_not_functions() abort
  let l:f = s:open('freeform') . '/typed.f90'
  execute 'silent edit! ' . fnameescape(l:f)
  for [l:lnum, l:what] in [[3, 'integer, parameter'], [4, 'type :: solver'],
        \ [12, 'real :: x'], [26, 'real(dp) :: x']]
    call cursor(l:lnum, 1)
    let l:got = textobj#find_bounds('func')
    call assert_notequal(l:lnum, l:got[0], l:what . ' must not start a function')
  endfor
endfunction

" A module containing `module procedure` must still span the whole module: the
" generic-interface line is not a module opening.
function! Test_module_with_module_procedure() abort
  let l:f = s:open('freeform') . '/typed.f90'
  call assert_equal([1, 40], s:bounds(l:f, 12, 'module'), 'module spans whole file')
endfunction

" A module whose name merely begins with `procedure` is a normal module.
function! Test_module_named_like_a_keyword() abort
  let l:dir = Vf90Fixture('textobj')
  let l:f = Vf90Write(l:dir . '/p.f90', [
        \ 'module procedures_mod',
        \ '  implicit none',
        \ 'contains',
        \ '  subroutine a()',
        \ '  end subroutine a',
        \ 'end module procedures_mod'])
  call assert_equal([1, 6], s:bounds(l:f, 2, 'module'), 'module procedures_mod')
endfunction

" Uppercase is as valid as lowercase and must not depend on 'ignorecase'.
function! Test_uppercase_constructs() abort
  let l:f = s:open('freeform') . '/upper.f90'
  call assert_equal([7, 12], s:bounds(l:f, 8, 'func'), 'SUBROUTINE')
  call assert_equal([1, 13], s:bounds(l:f, 8, 'module'), 'MODULE')
  call assert_equal([9, 11], s:bounds(l:f, 10, 'do'), 'DO / END DO')
  call assert_equal([3, 5], s:bounds(l:f, 4, 'block'), 'INTERFACE')
endfunction

function! Test_uppercase_unaffected_by_ignorecase() abort
  let l:f = s:open('freeform') . '/upper.f90'
  let l:saved = &ignorecase
  try
    set ignorecase
    call assert_equal([7, 12], s:bounds(l:f, 8, 'func'), 'with ignorecase')
    set noignorecase
    call assert_equal([7, 12], s:bounds(l:f, 8, 'func'), 'without ignorecase')
  finally
    let &ignorecase = l:saved
  endtry
endfunction

function! Test_nested_do_loops() abort
  let l:dir = Vf90Fixture('textobj')
  let l:f = Vf90Write(l:dir . '/n.f90', [
        \ 'subroutine nest()',
        \ '  do i = 1, 2',
        \ '    do j = 1, 2',
        \ '      print *, i',
        \ '    end do',
        \ '  end do',
        \ 'end subroutine nest'])
  call assert_equal([3, 5], s:bounds(l:f, 4, 'do'), 'inner loop')
  call assert_equal([2, 6], s:bounds(l:f, 2, 'do'), 'outer loop')
endfunction

function! Test_cursor_outside_any_construct() abort
  let l:dir = Vf90Fixture('textobj')
  let l:f = Vf90Write(l:dir . '/e.f90', ['! just a comment', '! and another'])
  call assert_equal([0, 0], s:bounds(l:f, 1, 'func'), 'no construct')
endfunction

function! Test_unknown_type_returns_zero() abort
  let l:f = s:open('freeform') . '/typed.f90'
  call assert_equal([0, 0], s:bounds(l:f, 12, 'not_a_construct'))
endfunction

" ]m walks every subprogram start in order.
function! Test_subprogram_motion_forward() abort
  let l:f = s:open('freeform') . '/typed.f90'
  execute 'silent edit! ' . fnameescape(l:f)
  call cursor(1, 1)
  let l:hops = []
  for l:i in range(6)
    call textobj#jump('subprog', 1, 0)
    call add(l:hops, line('.'))
  endfor
  call assert_equal([11, 16, 21, 25, 30, 37], l:hops, 'forward subprogram hops')
endfunction

function! Test_subprogram_motion_backward() abort
  let l:f = s:open('freeform') . '/typed.f90'
  execute 'silent edit! ' . fnameescape(l:f)
  call cursor(39, 1)
  call textobj#jump('subprog', 0, 0)
  call assert_equal(37, line('.'), 'backward to previous subprogram')
endfunction

" ---------------------------------------------------------------------------
" Fixed source form (FORTRAN 77 and fixed-form Fortran 90+).
" Line numbers refer to test/fixtures/fixedform/legacy.f.
" ---------------------------------------------------------------------------
function! Test_fixedform_is_detected_from_extension() abort
  let l:f = s:open('fixedform') . '/legacy.f'
  execute 'silent edit! ' . fnameescape(l:f)
  call assert_equal(1, textobj#is_fixed_form(), '.f must be read as fixed form')
endfunction

function! Test_freeform_is_detected_from_extension() abort
  let l:f = s:open('freeform') . '/typed.f90'
  execute 'silent edit! ' . fnameescape(l:f)
  call assert_equal(0, textobj#is_fixed_form(), '.f90 must be read as free form')
endfunction

" The buffer-local flag Vim's own ftplugin sets wins over the extension, so a
" fixed-form file named .f90 is handled correctly.
function! Test_fixedform_honours_buffer_flag() abort
  let l:dir = Vf90Fixture('textobj')
  let l:f = Vf90Write(l:dir . '/odd.f90', [
        \ '      SUBROUTINE ODD',
        \ '      WRITE(*,*) 1',
        \ '      END'])
  execute 'silent edit! ' . fnameescape(l:f)
  let b:fortran_fixed_source = 1
  try
    call assert_equal(1, textobj#is_fixed_form())
    call cursor(2, 1)
    call assert_equal([1, 3], textobj#find_bounds('func'), 'bare END in a .f90 file')
  finally
    unlet b:fortran_fixed_source
  endtry
endfunction

" A program unit ends at a bare END, with no keyword saying what is ending.
function! Test_fixedform_bare_end_closes_program_unit() abort
  let l:f = s:open('fixedform') . '/legacy.f'
  call assert_equal([1, 8], s:bounds(l:f, 3, 'module'), 'PROGRAM ... END')
  call assert_equal([10, 12], s:bounds(l:f, 11, 'func'), 'SUBROUTINE ... END')
endfunction

" Typed function declarations, including the INTEGER*4 extension form.
function! Test_fixedform_typed_functions() abort
  let l:f = s:open('fixedform') . '/legacy.f'
  call assert_equal([14, 17], s:bounds(l:f, 16, 'func'), 'REAL FUNCTION')
  call assert_equal([18, 21], s:bounds(l:f, 20, 'func'), 'INTEGER*4 FUNCTION')
endfunction

function! Test_fixedform_block_data() abort
  let l:f = s:open('fixedform') . '/legacy.f'
  call assert_equal([37, 40], s:bounds(l:f, 38, 'func'), 'BLOCK DATA ... END')
endfunction

" A labelled DO ends at the statement carrying its label, not at an END DO.
function! Test_fixedform_labelled_do() abort
  let l:f = s:open('fixedform') . '/legacy.f'
  call assert_equal([4, 6], s:bounds(l:f, 5, 'do'), 'DO 10 ... 10 CONTINUE')
endfunction

function! Test_fixedform_nested_labelled_do() abort
  let l:f = s:open('fixedform') . '/legacy.f'
  call assert_equal([25, 27], s:bounds(l:f, 26, 'do'), 'inner DO 30')
  call assert_equal([24, 28], s:bounds(l:f, 24, 'do'), 'outer DO 20')
endfunction

" Fixed-form Fortran 90 may still use END DO.
function! Test_fixedform_end_do_loop() abort
  let l:f = s:open('fixedform') . '/legacy.f'
  call assert_equal([29, 31], s:bounds(l:f, 30, 'do'), 'DO ... END DO')
endfunction

" C and * in column one are comments; they must not be mistaken for statements.
function! Test_fixedform_column_one_comments() abort
  let l:f = s:open('fixedform') . '/legacy.f'
  execute 'silent edit! ' . fnameescape(l:f)
  call assert_equal([10, 12], s:bounds(l:f, 11, 'func'),
        \ 'a C comment between units must not extend the previous one')
  call assert_equal([14, 17], s:bounds(l:f, 15, 'func'),
        \ 'a * comment must not extend the previous unit')
endfunction

" A continuation line carries a non-blank in column six and continues the
" statement above it, so it can neither open nor close a construct.
function! Test_fixedform_continuation_lines() abort
  let l:f = s:open('fixedform') . '/legacy.f'
  call assert_equal([33, 36], s:bounds(l:f, 35, 'func'), 'continued SUBROUTINE header')
endfunction

function! Test_fixedform_subprogram_motion() abort
  let l:f = s:open('fixedform') . '/legacy.f'
  execute 'silent edit! ' . fnameescape(l:f)
  call cursor(1, 1)
  let l:hops = []
  for l:i in range(6)
    call textobj#jump('subprog', 1, 0)
    call add(l:hops, line('.'))
  endfor
  call assert_equal([10, 14, 18, 22, 33, 37], l:hops, 'forward through fixed-form units')
endfunction

" Free form must be unaffected by any of the above.
function! Test_freeform_still_requires_explicit_end() abort
  let l:dir = Vf90Fixture('textobj')
  let l:f = Vf90Write(l:dir . '/bare.f90', [
        \ 'subroutine s()',
        \ '  integer :: i',
        \ 'end subroutine s'])
  call assert_equal([1, 3], s:bounds(l:f, 2, 'func'), 'free form is unchanged')
endfunction
