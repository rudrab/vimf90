"########################################################################
" test_doc.vim — FORD documentation configuration and the preview flow.
"########################################################################

function! s:project() abort
  let l:dir = Vf90Fixture('doc')
  call Vf90Write(l:dir . '/fpm.toml', ['name = "demo"'])
  call Vf90Write(l:dir . '/src/demo.f90', ['module demo', 'end module demo'])
  execute 'silent edit! ' . fnameescape(l:dir . '/src/demo.f90')
  return l:dir
endfunction

function! Test_find_ford_config_when_absent() abort
  let l:dir = s:project()
  call assert_equal('', doc#find_ford_config())
endfunction

function! Test_find_ford_config_by_conventional_name() abort
  let l:dir = s:project()
  call Vf90Write(l:dir . '/ford.md', ['project: demo', 'output_dir: ./doc'])
  call assert_equal(l:dir . '/ford.md', doc#find_ford_config())
endfunction

function! Test_create_default_ford_config() abort
  let l:dir = s:project()
  let l:cfg = doc#create_default_ford_config(l:dir)
  call assert_notequal('', l:cfg)
  call assert_equal(1, filereadable(l:cfg))
  call assert_match('\coutput_dir', join(readfile(l:cfg), "\n"))
endfunction

" ford_build takes an optional completion callback. Holding a Funcref in a
" variable whose name starts lowercase raises E704, which used to make every
" :FordPreview that had to build throw instead of building.
" Run the given command with ford unreachable. Actually invoking ford would be
" slow, would write a documentation tree, and would open a browser; the point
" here is the callback plumbing, which the missing-tool path exercises just as
" well and deterministically.
function! s:without_ford(cmd) abort
  let l:saved = $PATH
  let $PATH = Vf90Mkdir(Vf90Fixture('doc') . '/empty-path')
  let g:fortran_async = 0
  try
    execute a:cmd
  finally
    let $PATH = l:saved
  endtry
endfunction

" ford_build takes a completion callback. Holding a Funcref in a variable whose
" name starts lowercase raises E704, which used to make every :FordPreview that
" had to build throw instead of building.
function! Test_ford_build_invokes_its_callback() abort
  let l:dir = s:project()
  let g:vf90_called = -1
  function! Vf90FordDone(success) abort
    let g:vf90_called = a:success
  endfunction
  try
    call s:without_ford('call doc#ford_build(function("Vf90FordDone"))')
    call assert_equal(0, g:vf90_called, 'callback should have reported failure')
  catch
    call assert_report('ford_build threw: ' . v:exception)
  finally
    delfunction Vf90FordDone
    unlet g:vf90_called
  endtry
endfunction

" :FordPreview with no documentation present has to build first, which is the
" path that passes a lambda into ford_build.
function! Test_ford_preview_builds_when_docs_are_absent() abort
  let l:dir = s:project()
  try
    call s:without_ford('call doc#ford_preview()')
  catch
    call assert_report('ford_preview threw: ' . v:exception)
  endtry
endfunction

" With an index already on disk the browser is opened directly and no build is
" started. BROWSER/xdg-open is not invoked because ford_preview shells out via
" system(), which a stripped PATH renders harmless.
function! Test_ford_preview_uses_existing_docs() abort
  let l:dir = s:project()
  call Vf90Write(l:dir . '/doc/index.html', ['<html></html>'])
  try
    call s:without_ford('call doc#ford_preview()')
  catch
    call assert_report('ford_preview threw: ' . v:exception)
  endtry
  call assert_equal(1, filereadable(l:dir . '/doc/index.html'), 'docs left intact')
endfunction

" ---------------------------------------------------------------------------
" Docstring generation
" ---------------------------------------------------------------------------
function! Test_docstring_inserted_above_subprogram() abort
  let l:dir = Vf90Fixture('doc')
  call Vf90OpenScratch(l:dir . '/s.f90', [
        \ 'subroutine compute(a, b)',
        \ '  integer :: a, b',
        \ 'end subroutine compute'])
  call cursor(1, 1)
  try
    call doc#generate('ford')
  catch
    call assert_report('doc#generate threw: ' . v:exception)
    return
  endtry
  let l:text = join(getline(1, '$'), "\n")
  call assert_match('^!>', l:text, 'expected a FORD docstring marker')
  call assert_match('@param a', l:text, 'dummy arguments should be listed')
  call assert_match('@param b', l:text)
  call assert_match('subroutine compute', l:text, 'the subprogram must survive')
endfunction
