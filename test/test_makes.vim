"########################################################################
" test_makes.vim — compiling, linking and how build status is decided.
"
" The %t errorformat item consumes the first character of the severity word,
" so the warning rule must read '%tarning:' and not '%twarning:'. Getting that
" wrong makes every warning land in the quickfix list untyped, which reads as
" an error and turns a successful build into a reported failure.
"########################################################################

function! s:project() abort
  let l:dir = Vf90Fixture('makes')
  call Vf90Write(l:dir . '/Makefile', ['all:'])
  return l:dir
endfunction

function! s:open(dir, name, lines) abort
  call Vf90Write(a:dir . '/' . a:name, a:lines)
  execute 'silent edit! ' . fnameescape(a:dir . '/' . a:name)
endfunction

let s:clean = [
      \ 'program ok',
      \ '  implicit none',
      \ '  print *, "ok"',
      \ 'end program ok']

let s:warns = [
      \ 'program warns',
      \ '  implicit none',
      \ '  integer :: unused_var',
      \ '  print *, "hi"',
      \ 'end program warns']

let s:broken = [
      \ 'program broken',
      \ '  implicit none',
      \ '  integer :: i',
      \ '  i = "not an integer"',
      \ 'end program broken']

function! Test_compile_clean_source() abort
  call Vf90NeedExecutable('gfortran')
  let l:dir = s:project()
  call s:open(l:dir, 'ok.f90', s:clean)
  call assert_equal(1, makes#Fcompile(0), 'clean source must compile')
  call assert_equal(1, filereadable(l:dir . '/ok.o'))
endfunction

" A warning is not an error. gfortran exits 0 and writes the object file, so
" the build succeeded and Frun must not be blocked.
function! Test_warning_does_not_fail_the_build() abort
  call Vf90NeedExecutable('gfortran')
  let l:dir = s:project()
  call s:open(l:dir, 'warns.f90', s:warns)
  call profiles#set_profile('debug')
  call assert_equal(1, makes#Fcompile(0), 'a warning must not be reported as failure')
  call assert_equal(1, filereadable(l:dir . '/warns.o'), 'object file was produced')
endfunction

function! Test_error_fails_the_build() abort
  call Vf90NeedExecutable('gfortran')
  let l:dir = s:project()
  call s:open(l:dir, 'broken.f90', s:broken)
  call assert_equal(0, makes#Fcompile(0), 'a type error must fail')
  call assert_equal(0, filereadable(l:dir . '/broken.o'))
endfunction

" The classification the build status depends on, checked directly.
function! Test_errorformat_types_warnings_and_errors() abort
  call Vf90NeedExecutable('gfortran')
  let l:dir = s:project()
  call Vf90Write(l:dir . '/warns.f90', s:warns)
  call Vf90Write(l:dir . '/broken.f90', s:broken)
  call s:open(l:dir, 'warns.f90', s:warns)

  " Reuse the plugin's own errorformat by driving a real compile through it.
  call profiles#set_profile('debug')
  call makes#Fcompile(0)
  let l:types = map(filter(getqflist(), 'v:val.valid'), 'v:val.type')
  call assert_equal([], filter(copy(l:types), 'v:val ==# "E"'),
        \ 'a warning must not be typed as an error')
  call assert_notequal(-1, index(l:types, 'W'), 'warning should be typed W')

  call s:open(l:dir, 'broken.f90', s:broken)
  call makes#Fcompile(0)
  let l:types = map(filter(getqflist(), 'v:val.valid'), 'v:val.type')
  call assert_notequal(-1, index(l:types, 'E'), 'error should be typed E')
endfunction

function! Test_link_executable() abort
  call Vf90NeedExecutable('gfortran')
  let l:dir = s:project()
  call s:open(l:dir, 'ok.f90', s:clean)
  call assert_equal(1, makes#Fexe(0))
  call assert_equal(1, filereadable(l:dir . '/ok'), 'executable produced')
endfunction

" ---------------------------------------------------------------------------
" Asynchronous builds
" ---------------------------------------------------------------------------
function! Test_async_compile_succeeds() abort
  call Vf90NeedExecutable('gfortran')
  if !has('job') && !has('nvim')
    call Vf90Skip('no job support')
  endif
  let l:dir = s:project()
  call s:open(l:dir, 'ok.f90', s:clean)
  call makes#Fcompile(1)
  call assert_equal(1, Vf90WaitFor({-> filereadable(l:dir . '/ok.o')}, 20000),
        \ 'async build produced no object file')
endfunction

" A project path with a space must survive: the argument list goes straight to
" job_start with no shell in between, so nothing may be escaped.
function! Test_async_compile_with_space_in_path() abort
  call Vf90NeedExecutable('gfortran')
  if !has('job') && !has('nvim')
    call Vf90Skip('no job support')
  endif
  let l:dir = Vf90Mkdir(Vf90Fixture('makes') . '/with space')
  call Vf90Write(l:dir . '/fpm.toml', ['name = "demo"'])
  call s:open(l:dir, 'ok.f90', s:clean)
  call makes#Fcompile(1)
  call assert_equal(1, Vf90WaitFor({-> filereadable(l:dir . '/ok.o')}, 20000),
        \ 'async build failed under a path containing a space')
endfunction

function! Test_async_failure_populates_quickfix() abort
  call Vf90NeedExecutable('gfortran')
  if !has('job') && !has('nvim')
    call Vf90Skip('no job support')
  endif
  let l:dir = s:project()
  call s:open(l:dir, 'broken.f90', s:broken)
  call setqflist([], 'r')
  call makes#Fcompile(1)
  call assert_equal(1, Vf90WaitFor({-> !empty(filter(getqflist(), 'v:val.valid'))}, 20000),
        \ 'no diagnostics reached the quickfix list')
endfunction

" ---------------------------------------------------------------------------
" Include directories reach the compiler
" ---------------------------------------------------------------------------
function! Test_include_directory_is_passed_to_compiler() abort
  call Vf90NeedExecutable('gfortran')
  let l:dir = s:project()
  call Vf90Write(l:dir . '/include/constants.inc', ['integer, parameter :: magic = 7'])
  call s:open(l:dir, 'uses.f90', [
        \ 'module uses_inc',
        \ '  implicit none',
        \ "  include 'constants.inc'",
        \ 'end module uses_inc'])
  call assert_equal(1, makes#Fcompile(0), 'include/ was not on the include path')
endfunction
