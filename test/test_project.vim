"########################################################################
" test_project.vim — root detection, include paths, module search, delegation.
"########################################################################

function! s:project(kind) abort
  let l:dir = Vf90Fixture('project')
  call Vf90Write(l:dir . '/src/deep/a.f90', ['module a_mod', 'end module a_mod'])
  if a:kind ==# 'fpm'
    call Vf90Write(l:dir . '/fpm.toml', ['name = "demo"'])
  elseif a:kind ==# 'make'
    call Vf90Write(l:dir . '/Makefile', ['all:'])
  elseif a:kind ==# 'cmake'
    call Vf90Write(l:dir . '/CMakeLists.txt', ['project(demo)'])
  elseif a:kind ==# 'git'
    call Vf90Mkdir(l:dir . '/.git')
  endif
  execute 'silent edit! ' . fnameescape(l:dir . '/src/deep/a.f90')
  return l:dir
endfunction

function! Test_root_from_fpm_manifest() abort
  let l:dir = s:project('fpm')
  call assert_equal(l:dir, project#find_root())
  call assert_equal('fpm', project#detect_type())
endfunction

function! Test_root_from_makefile() abort
  let l:dir = s:project('make')
  call assert_equal(l:dir, project#find_root())
  call assert_equal('make', project#detect_type())
endfunction

function! Test_root_from_cmake() abort
  let l:dir = s:project('cmake')
  call assert_equal(l:dir, project#find_root())
  call assert_equal('cmake', project#detect_type())
endfunction

" .git is a directory, so the root is its parent and not .git itself.
function! Test_root_from_git_directory() abort
  let l:dir = s:project('git')
  call assert_equal(l:dir, project#find_root(), 'root must not be the .git dir')
  call assert_equal('single', project#detect_type())
endfunction

" findfile()/finddir() take a path list in which a space separates entries.
function! Test_root_with_space_in_path() abort
  let l:base = Vf90Mkdir(Vf90Fixture('project') . '/with space')
  call Vf90Write(l:base . '/fpm.toml', ['name = "demo"'])
  call Vf90Write(l:base . '/src/a.f90', ['module a_mod', 'end module a_mod'])
  execute 'silent edit! ' . fnameescape(l:base . '/src/a.f90')
  call assert_equal(l:base, project#find_root())
endfunction

function! Test_root_falls_back_to_start_dir() abort
  let l:dir = Vf90Fixture('project')
  call Vf90Write(l:dir . '/lonely.f90', ['program p', 'end program p'])
  execute 'silent edit! ' . fnameescape(l:dir . '/lonely.f90')
  call assert_equal(l:dir, project#find_root(), 'no indicator anywhere')
endfunction

" ---------------------------------------------------------------------------
" Delegation to an external project manager
" ---------------------------------------------------------------------------
function! Test_root_override_global() abort
  let l:dir = s:project('fpm')
  let g:fortran_project_root = '/somewhere/else'
  call assert_equal('/somewhere/else', project#find_root())
endfunction

function! Test_root_override_buffer_beats_global() abort
  let l:dir = s:project('fpm')
  let g:fortran_project_root = '/global'
  let b:fortran_project_root = '/buffer'
  try
    call assert_equal('/buffer', project#find_root())
  finally
    unlet b:fortran_project_root
  endtry
endfunction

" An explicit argument is a question about that directory, so the override
" must not answer it.
function! Test_explicit_argument_beats_override() abort
  let l:dir = s:project('fpm')
  let g:fortran_project_root = '/somewhere/else'
  call assert_equal(l:dir, project#find_root(l:dir . '/src/deep'))
endfunction

function! Test_root_provider_funcref() abort
  let l:dir = s:project('fpm')
  let g:Fortran_root_provider = {-> '/from/provider'}
  call assert_equal('/from/provider', project#find_root())
endfunction

" A provider that declines (returns empty) falls through to detection.
function! Test_root_provider_declining() abort
  let l:dir = s:project('fpm')
  let g:Fortran_root_provider = {-> ''}
  call assert_equal(l:dir, project#find_root())
endfunction

" call() takes a function name as readily as a Funcref, so both forms work.
function! Test_root_provider_accepts_function_name() abort
  let l:dir = s:project('fpm')
  function! Vf90DummyProvider() abort
    return '/named/function'
  endfunction
  let g:Fortran_root_provider = 'Vf90DummyProvider'
  try
    call assert_equal('/named/function', project#find_root())
  finally
    delfunction Vf90DummyProvider
  endtry
endfunction

" Vim refuses a Funcref in a variable whose name starts lowercase, so the
" provider options only exist capitalised. This pins that down so nobody
" reintroduces a lowercase alias that could never be assigned.
function! Test_lowercase_provider_name_is_impossible() abort
  try
    let g:fortran_root_provider = {-> '/nope'}
    call assert_report('expected E704 for a lowercase Funcref name')
  catch /E704/
  endtry
endfunction

function! Test_build_provider_intercepts() abort
  let l:dir = s:project('fpm')
  let g:vf90_seen = {}
  let g:Fortran_build_provider = {ctx -> extend(g:vf90_seen, ctx) isnot 0}
  try
    call assert_equal(1, project#build('--verbose'))
    call assert_equal(l:dir, get(g:vf90_seen, 'root', ''))
    call assert_equal('fpm', get(g:vf90_seen, 'type', ''))
    call assert_equal('--verbose', get(g:vf90_seen, 'args', ''))
  finally
    unlet g:vf90_seen
  endtry
endfunction

" ---------------------------------------------------------------------------
" Include directories
" ---------------------------------------------------------------------------
function! Test_include_dirs_cover_project_layout() abort
  let l:dir = s:project('fpm')
  call Vf90Mkdir(l:dir . '/include')
  let l:dirs = project#get_include_dirs()
  call assert_notequal(-1, index(l:dirs, l:dir), 'root')
  call assert_notequal(-1, index(l:dirs, l:dir . '/src'), 'src')
  call assert_notequal(-1, index(l:dirs, l:dir . '/include'), 'include')
endfunction

" compile_commands.json is authoritative for the module dir, but it carries no
" include/ path, so it must extend the heuristic rather than replace it.
function! Test_compile_commands_extends_not_replaces() abort
  let l:dir = s:project('fpm')
  call Vf90Mkdir(l:dir . '/include')
  call Vf90Mkdir(l:dir . '/build/gfortran_ABCDEF0123456789')
  call Vf90Write(l:dir . '/build/compile_commands.json', [json_encode([{
        \ 'arguments': ['gfortran', '-c', 'src/a.f90', '-J', 'build/gfortran_ABCDEF0123456789',
        \               '-Ibuild/gfortran_ABCDEF0123456789'],
        \ 'directory': l:dir, 'file': 'src/a.f90'}])])
  let l:dirs = project#get_include_dirs()
  call assert_equal(l:dir . '/build/gfortran_ABCDEF0123456789', l:dirs[0], 'manifest dir leads')
  call assert_notequal(-1, index(l:dirs, l:dir . '/include'), 'include/ still present')
  call assert_equal(len(l:dirs), len(uniq(sort(copy(l:dirs)))), 'no duplicates')
endfunction

function! Test_compile_commands_accepts_command_string_form() abort
  let l:dir = s:project('fpm')
  call Vf90Mkdir(l:dir . '/build/gfortran_ABCDEF0123456789')
  call Vf90Write(l:dir . '/build/compile_commands.json', [json_encode([{
        \ 'command': 'gfortran -c src/a.f90 -Ibuild/gfortran_ABCDEF0123456789',
        \ 'directory': l:dir, 'file': 'src/a.f90'}])])
  call assert_equal(l:dir . '/build/gfortran_ABCDEF0123456789',
        \ project#get_include_dirs()[0])
endfunction

function! Test_malformed_compile_commands_is_survivable() abort
  let l:dir = s:project('fpm')
  call Vf90Write(l:dir . '/build/compile_commands.json', ['{not json at all'])
  let l:dirs = project#get_include_dirs()
  call assert_notequal(-1, index(l:dirs, l:dir . '/src'), 'falls back to heuristic')
endfunction

" Hash directories are matched by shape, so every compiler is covered and
" build/dependencies is not mistaken for one.
function! Test_build_hash_dirs_any_compiler() abort
  let l:dir = s:project('fpm')
  for l:name in ['gfortran_0123456789ABCDEF', 'nvfortran_FEDCBA9876543210',
        \ 'flang_AAAABBBBCCCCDDDD', 'ifort_1111222233334444']
    call Vf90Mkdir(l:dir . '/build/' . l:name)
  endfor
  call Vf90Mkdir(l:dir . '/build/dependencies/other/src')
  let l:dirs = project#get_include_dirs()
  for l:name in ['gfortran_0123456789ABCDEF', 'nvfortran_FEDCBA9876543210',
        \ 'flang_AAAABBBBCCCCDDDD', 'ifort_1111222233334444']
    call assert_notequal(-1, index(l:dirs, l:dir . '/build/' . l:name), l:name)
  endfor
  call assert_equal(-1, index(l:dirs, l:dir . '/build/dependencies'),
        \ 'build/dependencies is not a hash dir')
endfunction

" The list form is escaped for the shell, the flag form is not.
function! Test_include_flags_are_escaped() abort
  let l:base = Vf90Mkdir(Vf90Fixture('project') . '/with space')
  call Vf90Write(l:base . '/fpm.toml', ['name = "demo"'])
  call Vf90Write(l:base . '/src/a.f90', ['module a_mod', 'end module a_mod'])
  execute 'silent edit! ' . fnameescape(l:base . '/src/a.f90')
  call assert_match('\\ ', project#get_include_flags(), 'flags escape the space')
  for l:dir in project#get_include_dirs()
    call assert_notmatch('\\', l:dir, 'raw dirs are unescaped for job_start')
  endfor
endfunction

" ---------------------------------------------------------------------------
" Module search
" ---------------------------------------------------------------------------
function! Test_find_module_jumps_to_definition() abort
  let l:dir = s:project('fpm')
  call Vf90Write(l:dir . '/src/deep/target.f90',
        \ repeat(['! filler'], 200) + ['module far_away_mod', 'end module far_away_mod'])
  call project#find_module('far_away_mod')
  call assert_equal('target.f90', expand('%:t'))
  call assert_equal(201, line('.'), 'well past any line cap')
endfunction

function! Test_find_module_is_case_insensitive() abort
  let l:dir = s:project('fpm')
  call Vf90Write(l:dir . '/src/deep/upper.f90', ['MODULE SHOUTY_MOD', 'END MODULE SHOUTY_MOD'])
  call project#find_module('shouty_mod')
  call assert_equal('upper.f90', expand('%:t'))
endfunction

" A module whose name is a prefix of another must not be matched.
function! Test_find_module_respects_word_boundary() abort
  let l:dir = s:project('fpm')
  call Vf90Write(l:dir . '/src/deep/pair.f90',
        \ ['module solver_extended', 'end module solver_extended'])
  let l:before = expand('%:p')
  call project#find_module('solver')
  call assert_equal(l:before, expand('%:p'), 'solver must not match solver_extended')
endfunction

function! Test_find_module_preserves_quickfix() abort
  let l:dir = s:project('fpm')
  call setqflist([], 'r', {'title': 'Fortran Build',
        \ 'items': [{'filename': 'x.f90', 'lnum': 3, 'text': 'kept'}]})
  call project#find_module('a_mod')
  call assert_equal('Fortran Build', getqflist({'title': 1}).title)
  call assert_equal('kept', getqflist()[0].text)
endfunction

function! Test_find_module_missing_stays_put() abort
  let l:dir = s:project('fpm')
  let l:before = expand('%:p')
  call project#find_module('definitely_not_here_mod')
  call assert_equal(l:before, expand('%:p'))
endfunction
