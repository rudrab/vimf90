"########################################################################
" test_lint.vim — linting through fortitude (:FortranLint).
"
" fortitude's own findings will change as it gains rules, so these assert the
" plumbing rather than any particular rule: that output reaches the quickfix
" list with file, line and column intact, that the summary block does not, and
" that finding something is reported as a count rather than as a failure.
"########################################################################

function! s:need_fortitude() abort
  call Vf90NeedExecutable('fortitude')
endfunction

" A file fortitude has something to say about: integer*4 is non-standard.
function! s:bad_file(dir) abort
  return Vf90OpenScratch(a:dir . '/bad.f90', [
        \ 'program demo',
        \ 'implicit none',
        \ 'integer*4 :: i',
        \ 'i = 1',
        \ 'end program demo'])
endfunction

function! Test_lint_reports_findings_in_quickfix() abort
  call s:need_fortitude()
  let l:dir = Vf90Fixture('lint')
  call s:bad_file(l:dir)
  let g:fortran_async = 0
  let l:msg = execute('call lint#run()')

  let l:items = filter(getqflist(), 'v:val.valid')
  call assert_notequal([], l:items, 'fortitude found nothing to report')
  call assert_match('found \d\+ issue', l:msg, 'the count should be reported')
  call assert_notmatch('fail', l:msg, 'findings are not a failure')

  let l:first = l:items[0]
  call assert_equal('bad.f90', fnamemodify(bufname(l:first.bufnr), ':t'))
  call assert_notequal(0, l:first.lnum, 'line number missing')
  call assert_notequal(0, l:first.col, 'column missing')
  call assert_notequal('', l:first.text, 'message missing')
endfunction

" The trailing summary -- the file count, the totals, the hint about `explain`
" -- must not become quickfix entries.
function! Test_lint_drops_the_summary_block() abort
  call s:need_fortitude()
  let l:dir = Vf90Fixture('lint')
  call s:bad_file(l:dir)
  let g:fortran_async = 0
  call lint#run()
  for l:item in filter(getqflist(), 'v:val.valid')
    call assert_notmatch('files scanned', l:item.text)
    call assert_notmatch('Number of errors', l:item.text)
    call assert_notmatch('fortitude explain', l:item.text)
  endfor
endfunction

function! Test_lint_clean_file_reports_no_issues() abort
  call s:need_fortitude()
  let l:dir = Vf90Fixture('lint')
  " Written to satisfy the rules fortitude applies by default.
  call Vf90OpenScratch(l:dir . '/clean.f90', [
        \ 'module clean_mod',
        \ '  implicit none (type, external)',
        \ '  private',
        \ '  public :: answer',
        \ 'contains',
        \ '  integer function answer()',
        \ '    answer = 42',
        \ '  end function answer',
        \ 'end module clean_mod'])
  let g:fortran_async = 0
  let l:msg = execute('call lint#run()')
  if !empty(filter(getqflist(), 'v:val.valid'))
    call Vf90Skip('this fortitude has rules the sample does not satisfy')
  endif
  call assert_match('no issues', l:msg)
endfunction

function! Test_lint_project_scan() abort
  call s:need_fortitude()
  let l:dir = Vf90Fixture('lint')
  call Vf90Write(l:dir . '/fpm.toml', ['name = "demo"'])
  call Vf90Write(l:dir . '/src/deep/bad.f90', [
        \ 'module bad_mod', 'implicit none', 'integer*4 :: i', 'end module bad_mod'])
  call Vf90OpenScratch(l:dir . '/src/main.f90', ['program p', 'end program p'])
  let g:fortran_async = 0
  call lint#run('!')
  let l:files = map(filter(getqflist(), 'v:val.valid'), 'fnamemodify(bufname(v:val.bufnr), ":t")')
  call assert_notequal(-1, index(l:files, 'bad.f90'), 'the project scan missed a nested file')
endfunction

function! Test_lint_without_fortitude_warns_and_does_not_throw() abort
  let l:dir = Vf90Fixture('lint')
  call s:bad_file(l:dir)
  let g:fortran_fortitude_command = 'vf90-no-such-linter'
  try
    let l:msg = execute('call lint#run()')
    call assert_match('not installed', l:msg)
  catch
    call assert_report('lint#run threw: ' . v:exception)
  finally
    unlet g:fortran_fortitude_command
  endtry
endfunction

function! Test_lint_async_populates_quickfix() abort
  call s:need_fortitude()
  if !has('job') && !has('nvim')
    call Vf90Skip('no job support')
  endif
  let l:dir = Vf90Fixture('lint')
  call s:bad_file(l:dir)
  call setqflist([], 'r')
  call lint#run()
  call assert_equal(1, Vf90WaitFor({-> !empty(filter(getqflist(), 'v:val.valid'))}, 20000),
        \ 'the asynchronous run produced no quickfix entries')
endfunction

" A path with a space must survive the argument list.
function! Test_lint_path_with_space() abort
  call s:need_fortitude()
  let l:dir = Vf90Mkdir(Vf90Fixture('lint') . '/with space')
  call s:bad_file(l:dir)
  let g:fortran_async = 0
  call lint#run()
  call assert_notequal([], filter(getqflist(), 'v:val.valid'),
        \ 'nothing reported for a path containing a space')
endfunction

function! Test_lint_extra_args_are_passed() abort
  call s:need_fortitude()
  let l:dir = Vf90Fixture('lint')
  call s:bad_file(l:dir)
  let g:fortran_async = 0
  " --select restricts the run to one rule, so the findings must all be it.
  let g:fortran_fortitude_args = '--select PORT021'
  try
    call lint#run()
    for l:item in filter(getqflist(), 'v:val.valid')
      call assert_match('PORT021', l:item.text, 'g:fortran_fortitude_args was ignored')
    endfor
  finally
    unlet g:fortran_fortitude_args
  endtry
endfunction
