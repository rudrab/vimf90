"########################################################################
" test_fpm.vim — fpm project discovery, targets and command completion.
"########################################################################

function! s:fpm_project() abort
  let l:dir = Vf90Fixture('fpm')
  call Vf90Write(l:dir . '/fpm.toml', ['name = "demo"', 'version = "0.1.0"'])
  call Vf90Write(l:dir . '/src/demo.f90', [
        \ 'module demo',
        \ '  implicit none',
        \ 'contains',
        \ '  subroutine hello()',
        \ '    print *, "hello"',
        \ '  end subroutine hello',
        \ 'end module demo'])
  call Vf90Write(l:dir . '/app/main.f90', [
        \ 'program main', '  use demo', '  call hello()', 'end program main'])
  call Vf90Write(l:dir . '/test/check.f90', ['program check', 'end program check'])
  execute 'silent edit! ' . fnameescape(l:dir . '/src/demo.f90')
  return l:dir
endfunction

function! Test_fpm_root_discovery() abort
  let l:dir = s:fpm_project()
  call assert_equal(l:dir, fpm#find_root())
endfunction

function! Test_fpm_root_absent_outside_a_project() abort
  let l:dir = Vf90Fixture('fpm')
  call Vf90Write(l:dir . '/loose.f90', ['program p', 'end program p'])
  execute 'silent edit! ' . fnameescape(l:dir . '/loose.f90')
  call assert_equal('', fpm#find_root())
endfunction

function! Test_app_targets_are_listed() abort
  let l:dir = s:fpm_project()
  call Vf90Write(l:dir . '/app/second.f90', ['program second', 'end program second'])
  let l:targets = fpm#list_app_targets()
  call assert_notequal(-1, index(l:targets, 'main'))
  call assert_notequal(-1, index(l:targets, 'second'))
endfunction

function! Test_test_targets_are_listed() abort
  let l:dir = s:fpm_project()
  call assert_notequal(-1, index(fpm#list_test_targets(), 'check'))
endfunction

function! Test_targets_empty_outside_a_project() abort
  let l:dir = Vf90Fixture('fpm')
  call Vf90Write(l:dir . '/loose.f90', ['program p', 'end program p'])
  execute 'silent edit! ' . fnameescape(l:dir . '/loose.f90')
  call assert_equal([], fpm#list_app_targets())
endfunction

function! Test_subcommand_completion() abort
  let l:got = fpm#complete('', 'FortranFpm ', 11)
  let l:list = type(l:got) == v:t_list ? l:got : split(l:got, "\n")
  for l:sub in ['build', 'run', 'test']
    call assert_notequal(-1, index(l:list, l:sub), l:sub . ' should be offered')
  endfor
endfunction

function! Test_app_target_completion_filters_on_prefix() abort
  let l:dir = s:fpm_project()
  call Vf90Write(l:dir . '/app/second.f90', ['program second', 'end program second'])
  let l:got = fpm#complete_app_targets('se', 'FortranFpmRun se', 16)
  let l:list = type(l:got) == v:t_list ? l:got : split(l:got, "\n")
  call assert_notequal(-1, index(l:list, 'second'))
  call assert_equal(-1, index(l:list, 'main'), 'prefix must filter')
endfunction

" ---------------------------------------------------------------------------
" Building, when fpm is installed
" ---------------------------------------------------------------------------
function! Test_fpm_build_succeeds_and_writes_fortls() abort
  call Vf90NeedExecutable('fpm')
  call Vf90NeedExecutable('gfortran')
  let l:dir = s:fpm_project()
  call assert_equal(1, fpm#execute('build', '', 0), 'synchronous fpm build')
  call assert_equal(1, filereadable(l:dir . '/.fortls'),
        \ 'a successful build should refresh the LSP manifest')
endfunction

function! Test_fpm_build_failure_is_reported() abort
  call Vf90NeedExecutable('fpm')
  call Vf90NeedExecutable('gfortran')
  let l:dir = s:fpm_project()
  call Vf90Write(l:dir . '/src/demo.f90', [
        \ 'module demo', '  implicit none', '  integer :: i = "text"', 'end module demo'])
  call assert_equal(0, fpm#execute('build', '', 0), 'a broken build must report failure')
endfunction

" A release build must actually carry --profile release, including on the
" synchronous path where the flags used to be dropped.
function! Test_release_profile_reaches_fpm() abort
  call Vf90NeedExecutable('fpm')
  call Vf90NeedExecutable('gfortran')
  let l:dir = s:fpm_project()
  call profiles#set_profile('release')
  call assert_equal(1, fpm#execute('build', '', 0))
  let l:cc = l:dir . '/build/compile_commands.json'
  if !filereadable(l:cc)
    call Vf90Skip('this fpm does not emit compile_commands.json')
  endif
  let l:entries = json_decode(join(readfile(l:cc), ''))
  let l:args = join(map(copy(l:entries), 'join(get(v:val, "arguments", []), " ")'), ' ')
  call assert_match('-O3', l:args, 'release optimisation flags missing')
endfunction

function! Test_async_fpm_build_refreshes_fortls() abort
  call Vf90NeedExecutable('fpm')
  call Vf90NeedExecutable('gfortran')
  if !has('job') && !has('nvim')
    call Vf90Skip('no job support')
  endif
  let l:dir = s:fpm_project()
  call fpm#execute('build', '', 1)
  call assert_equal(1, Vf90WaitFor({-> filereadable(l:dir . '/.fortls')}, 60000),
        \ 'async build did not trigger .fortls generation')
endfunction
