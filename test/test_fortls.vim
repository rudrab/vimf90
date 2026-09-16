"########################################################################
" test_fortls.vim — generated .fortls manifests.
"
" The semantics being honoured here were read off fortls 1.12's source:
"   * excl_paths is exact string matching, not globs
"   * explicit source_dirs are NOT recursive, so every directory is listed
"   * fortls never reads .mod; dependency sources must be listed to resolve
"########################################################################

function! s:fpm_project(...) abort
  let l:dir = Vf90Fixture('fortls')
  call Vf90Write(l:dir . '/fpm.toml', a:0 > 0 ? a:1 : ['name = "demo"'])
  call Vf90Write(l:dir . '/src/demo.f90', ['module demo', 'end module demo'])
  call Vf90Write(l:dir . '/app/main.f90', ['program main', 'end program main'])
  call Vf90Write(l:dir . '/test/check.f90', ['program check', 'end program check'])
  return l:dir
endfunction

function! s:read_config(dir) abort
  return json_decode(join(readfile(a:dir . '/.fortls'), "\n"))
endfunction

function! Test_generate_lists_standard_layout() abort
  let l:dir = s:fpm_project()
  call assert_equal(1, fortls#generate(l:dir))
  let l:cfg = s:read_config(l:dir)
  call assert_equal(['app', 'src', 'test'], sort(l:cfg.source_dirs))
  call assert_equal(['build', '.git'], l:cfg.excl_paths)
  call assert_equal('vimf90', l:cfg._generated_by)
endfunction

" fortls does not recurse into explicitly configured source_dirs, so a nested
" directory is invisible unless it is named.
function! Test_generate_lists_nested_directories() abort
  let l:dir = s:fpm_project()
  call Vf90Write(l:dir . '/src/utils/helper.f90', ['module helper', 'end module helper'])
  call Vf90Write(l:dir . '/src/utils/deep/deeper.f90', ['module deeper', 'end module deeper'])
  call fortls#generate(l:dir)
  let l:dirs = s:read_config(l:dir).source_dirs
  call assert_notequal(-1, index(l:dirs, 'src/utils'), 'src/utils')
  call assert_notequal(-1, index(l:dirs, 'src/utils/deep'), 'src/utils/deep')
endfunction

" Nested directories without Fortran sources are noise and are left out.
function! Test_generate_skips_sourceless_subdirectories() abort
  let l:dir = s:fpm_project()
  call Vf90Mkdir(l:dir . '/src/empty')
  call Vf90Write(l:dir . '/src/data/values.csv', ['1,2,3'])
  call fortls#generate(l:dir)
  let l:dirs = s:read_config(l:dir).source_dirs
  call assert_equal(-1, index(l:dirs, 'src/empty'), 'empty dir')
  call assert_equal(-1, index(l:dirs, 'src/data'), 'non-Fortran dir')
endfunction

" build/<compiler>_<hash> directories are never listed, which is what makes the
" generated config immune to fpm's hash churn.
function! Test_generate_never_lists_build_hash_dirs() abort
  let l:dir = s:fpm_project()
  for l:hash in ['gfortran_AAAA1111BBBB2222', 'gfortran_CCCC3333DDDD4444']
    call Vf90Write(l:dir . '/build/' . l:hash . '/src/demo.f90', ['module demo', 'end module demo'])
  endfor
  call fortls#generate(l:dir)
  for l:d in s:read_config(l:dir).source_dirs
    call assert_notmatch('^build/gfortran_', l:d, 'stale hash dir leaked in')
  endfor
endfunction

" Dependency sources live under build/, which is excluded, so they have to be
" listed explicitly or dependency modules stop resolving.
function! Test_generate_includes_dependency_sources() abort
  let l:dir = s:fpm_project()
  call Vf90Write(l:dir . '/build/dependencies/mydep/src/mydep.f90',
        \ ['module mydep_mod', 'end module mydep_mod'])
  call fortls#generate(l:dir)
  call assert_notequal(-1, index(s:read_config(l:dir).source_dirs,
        \ 'build/dependencies/mydep/src'))
endfunction

function! Test_generate_honours_custom_source_dir() abort
  let l:dir = s:fpm_project(['name = "demo"', '[library]', 'source-dir = "sources"'])
  call Vf90Write(l:dir . '/sources/lib.f90', ['module lib', 'end module lib'])
  call fortls#generate(l:dir)
  call assert_notequal(-1, index(s:read_config(l:dir).source_dirs, 'sources'))
endfunction

function! Test_generate_requires_fpm_manifest() abort
  let l:dir = Vf90Fixture('fortls')
  call Vf90Write(l:dir . '/src/a.f90', ['module a', 'end module a'])
  call assert_equal(0, fortls#generate(l:dir), 'not an fpm project')
  call assert_equal(0, filereadable(l:dir . '/.fortls'))
endfunction

" ---------------------------------------------------------------------------
" Not clobbering the user
" ---------------------------------------------------------------------------
function! Test_handwritten_config_is_preserved() abort
  let l:dir = s:fpm_project()
  let l:mine = ['{"source_dirs": ["mine"]}']
  call Vf90Write(l:dir . '/.fortls', l:mine)
  call assert_equal(0, fortls#generate(l:dir), 'declines to overwrite')
  call assert_equal(l:mine, readfile(l:dir . '/.fortls'))
endfunction

function! Test_unparseable_config_is_preserved() abort
  let l:dir = s:fpm_project()
  let l:broken = ['{ this is not json']
  call Vf90Write(l:dir . '/.fortls', l:broken)
  call assert_equal(0, fortls#generate(l:dir))
  call assert_equal(l:broken, readfile(l:dir . '/.fortls'))
endfunction

function! Test_own_config_is_regenerated() abort
  let l:dir = s:fpm_project()
  call fortls#generate(l:dir)
  call Vf90Write(l:dir . '/src/utils/helper.f90', ['module helper', 'end module helper'])
  call assert_equal(1, fortls#generate(l:dir))
  call assert_notequal(-1, index(s:read_config(l:dir).source_dirs, 'src/utils'))
endfunction

" A rebuild must not churn the file's mtime when nothing has changed.
function! Test_unchanged_config_is_not_rewritten() abort
  let l:dir = s:fpm_project()
  call fortls#generate(l:dir)
  let l:before = readfile(l:dir . '/.fortls')
  call fortls#generate(l:dir)
  call assert_equal(l:before, readfile(l:dir . '/.fortls'))
  " Prove the guard compares content, not a compact encoding that never matches.
  let l:marker = l:dir . '/.fortls'
  let l:mtime = getftime(l:marker)
  sleep 1100m
  call fortls#generate(l:dir)
  call assert_equal(l:mtime, getftime(l:marker), 'file was rewritten needlessly')
endfunction

" ---------------------------------------------------------------------------
" Paths that are not well behaved
" ---------------------------------------------------------------------------
function! Test_generate_with_space_in_path() abort
  let l:base = Vf90Mkdir(Vf90Fixture('fortls') . '/with space')
  call Vf90Write(l:base . '/fpm.toml', ['name = "demo"'])
  call Vf90Write(l:base . '/src/nested/a.f90', ['module a', 'end module a'])
  call assert_equal(1, fortls#generate(l:base))
  call assert_notequal(-1, index(s:read_config(l:base).source_dirs, 'src/nested'))
endfunction

" Glob and regex metacharacters in the project path must be treated as data.
function! Test_generate_with_metacharacters_in_path() abort
  for l:odd in ['brackets[1]', 'star*name', 'brace{a,b}']
    let l:base = Vf90Mkdir(Vf90Fixture('fortls') . '/' . l:odd)
    call Vf90Write(l:base . '/fpm.toml', ['name = "demo"'])
    call Vf90Write(l:base . '/src/nested/a.f90', ['module a', 'end module a'])
    call fortls#generate(l:base)
    call assert_notequal(-1, index(s:read_config(l:base).source_dirs, 'src/nested'),
          \ 'nested dir lost under ' . l:odd)
  endfor
endfunction

function! Test_generate_accepts_trailing_slash_root() abort
  let l:dir = s:fpm_project()
  call Vf90Write(l:dir . '/src/nested/a.f90', ['module a', 'end module a'])
  call assert_equal(1, fortls#generate(l:dir . '/'))
  call assert_notequal(-1, index(s:read_config(l:dir).source_dirs, 'src/nested'))
endfunction

function! Test_generated_config_is_valid_json() abort
  let l:dir = s:fpm_project()
  call Vf90Write(l:dir . '/src/utils/a.f90', ['module a', 'end module a'])
  call fortls#generate(l:dir)
  let l:cfg = s:read_config(l:dir)
  call assert_equal(v:t_dict, type(l:cfg))
  call assert_equal(v:t_list, type(l:cfg.source_dirs))
endfunction

" ---------------------------------------------------------------------------
" Agreement with the real language server
" ---------------------------------------------------------------------------
function! Test_fortls_indexes_exactly_the_listed_dirs() abort
  call Vf90NeedExecutable('fortls')
  let l:dir = s:fpm_project()
  call Vf90Write(l:dir . '/src/utils/helper.f90', ['module helper_mod', 'end module helper_mod'])
  call Vf90Write(l:dir . '/build/dependencies/mydep/src/mydep.f90',
        \ ['module mydep_mod', 'end module mydep_mod'])
  call Vf90Write(l:dir . '/build/gfortran_AAAA1111BBBB2222/src/demo.f90',
        \ ['module demo', 'end module demo'])
  call fortls#generate(l:dir)

  let l:out = system('cd ' . shellescape(l:dir)
        \ . ' && fortls --debug_rootpath . --debug_workspace_symbols mod 2>&1')
  call assert_notmatch('does not exist', l:out, 'fortls rejected a source_dirs entry')
  call assert_notmatch('build/gfortran_', l:out, 'a stale hash dir was indexed')
  call assert_match('helper_mod', l:out, 'nested module not found')
  call assert_match('mydep_mod', l:out, 'dependency module not found')
endfunction
