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
" Known gap: fixed-form (F77) sources.
"
" These record what is not supported rather than asserting it is correct. If
" fixed-form support is added, drop the skip and the assertions should pass.
" ---------------------------------------------------------------------------
function! Test_fixedform_constructs() abort
  let l:f = s:open('fixedform') . '/legacy.f'
  let l:sub = s:bounds(l:f, 11, 'func')
  if l:sub ==# [0, 0]
    call Vf90Skip('fixed-form is not supported: bare END, labelled DO, column-1 comments')
  endif
  call assert_equal([10, 12], l:sub, 'SUBROUTINE ... END')
  call assert_equal([4, 6], s:bounds(l:f, 5, 'do'), 'DO 10 ... 10 CONTINUE')
endfunction
