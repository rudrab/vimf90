"########################################################################
" File:          test/run.vim
" License:       GPLv3
" Description:   Test runner for vimf90.
"
"   sh test/run.sh                 run everything
"   sh test/run.sh textobj project run only those files
"   VF90_TEST=Test_foo sh test/run.sh   run one test
"
" Each test/test_*.vim defines functions named Test_*. A test passes when it
" leaves v:errors empty; it may call Vf90Skip() to bow out.
"########################################################################

let s:testdir = expand('<sfile>:p:h')
execute 'source ' . fnameescape(s:testdir . '/harness.vim')

" In silent-ex mode :echo and :echomsg go nowhere, so results are appended to a
" file as they happen. Appending rather than buffering means that if Vim hangs
" or dies mid-suite, everything up to that point is still on disk.
let s:report = $VF90_REPORT
if empty(s:report)
  let s:report = g:vf90_scratch . '/report.txt'
endif
call Vf90Mkdir(fnamemodify(s:report, ':h'))
call writefile([], s:report)

function! s:out(msg) abort
  call writefile([a:msg], s:report, 'a')
endfunction

" The name of the test now running. The report only gains a line once a test
" finishes, so a test that hangs leaves no trace in it; this file is what
" run.sh reads to name the culprit when the watchdog fires.
let s:current = s:report . '.current'
" Exported so a test can narrow a hang further with Vf90Mark().
let g:vf90_current = s:current

function! s:mark_running(name) abort
  call writefile([a:name], s:current)
endfunction

function! s:mark_idle() abort
  call delete(s:current)
endfunction

let s:only = $VF90_TEST
let s:filter = split($VF90_FILES)

function! s:test_files() abort
  let l:files = sort(glob(s:testdir . '/test_*.vim', 0, 1))
  if empty(s:filter)
    return l:files
  endif
  return filter(l:files, {_, f -> index(s:filter, fnamemodify(f, ':t:r')[5:]) >= 0
        \ || index(s:filter, fnamemodify(f, ':t:r')) >= 0})
endfunction

" Names of Test_* functions currently defined, in source order.
function! s:test_names() abort
  let l:names = []
  for l:line in split(execute('function /^Test_'), "\n")
    let l:name = matchstr(l:line, '^function \zs\w\+\ze(')
    if !empty(l:name) && (empty(s:only) || l:name ==# s:only)
      call add(l:names, l:name)
    endif
  endfor
  return l:names
endfunction

let s:pass = 0
let s:fail = 0
let s:skip = 0
let s:failures = []

function! s:run_one(name) abort
  let v:errors = []
  call s:mark_running(a:name)
  call Vf90ResetOptions()
  try
    call call(a:name, [])
  catch /^VF90SKIP:/
    let s:skip += 1
    call s:out(printf('  ~ %-44s skipped: %s', a:name, substitute(v:exception, '^VF90SKIP:', '', '')))
    call Vf90Wipe()
    call s:mark_idle()
    return
  catch
    call add(v:errors, 'threw ' . v:exception . ' at ' . v:throwpoint)
  endtry
  " Teardown is marked separately: wiping a terminal buffer is itself a
  " candidate for hanging, and it must not be blamed on the test body.
  call s:mark_running(a:name . ' [teardown]')
  call Vf90Wipe()

  call s:mark_idle()
  if empty(v:errors)
    let s:pass += 1
    call s:out(printf('  . %s', a:name))
  else
    let s:fail += 1
    call s:out(printf('  X %s', a:name))
    for l:err in v:errors
      call s:out('      ' . substitute(l:err, '\n', ' ', 'g'))
      call add(s:failures, a:name . ': ' . substitute(l:err, '\n', ' ', 'g'))
    endfor
  endif
endfunction

function! s:main() abort
  call Vf90Mkdir(g:vf90_scratch)
  " Anything already running belongs to someone else; only what this run adds
  " counts as a leak.
  call Vf90MarkStubBaseline()
  " Work from the scratch directory. Compilers drop artefacts relative to the
  " current directory -- gfortran writes .mod files there -- and no test may
  " leave anything behind in the repository.
  execute 'cd ' . fnameescape(g:vf90_scratch)
  let l:start = reltime()

  for l:file in s:test_files()
    " Forget the previous file's tests so names are never run twice.
    for l:stale in s:test_names()
      execute 'delfunction ' . l:stale
    endfor
    call s:out(fnamemodify(l:file, ':t'))
    execute 'source ' . fnameescape(l:file)
    for l:name in s:test_names()
      call s:run_one(l:name)
    endfor
  endfor

  " A test that spawns a process must reap it. A leak here is how a wedged run
  " leaves editors and REPL stubs behind for someone to find hours later, so it
  " is reported as a failure rather than tidied away in silence.
  let l:leaked = Vf90LeakedProcesses()
  if !empty(l:leaked)
    let s:fail += 1
    call s:out(printf('  X process leak: %d REPL stub(s) still running: %s',
          \ len(l:leaked), join(l:leaked, ' ')))
    call add(s:failures, 'process leak: ' . join(l:leaked, ' '))
    call Vf90KillLeaked()
  endif

  let l:elapsed = split(reltimestr(reltime(l:start)))[0]
  call s:out('')
  call s:out(printf('%d passed, %d failed, %d skipped in %ss', s:pass, s:fail, s:skip, l:elapsed))
  if s:fail > 0
    call s:out('')
    call s:out('Failures:')
    for l:f in s:failures
      call s:out('  ' . l:f)
    endfor
  endif

  call delete(g:vf90_scratch, 'rf')
  execute 'cquit' . (s:fail > 0 ? ' 1' : ' 0')
endfunction

call s:main()
