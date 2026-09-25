"########################################################################
" File:          test/harness.vim
" License:       GPLv3
" Description:   Helpers shared by the vimf90 test suite.
"
" Assertions come from Vim's own assert_* family, which appends to v:errors;
" the runner clears that before each test and reports whatever accumulated.
" Nothing here depends on an external test plugin.
"########################################################################

" Root for scratch fixtures. Everything a test writes lives under here and is
" removed when the suite finishes, so a run never touches the working tree.
let g:vf90_scratch = fnamemodify(tempname(), ':h') . '/vimf90-test-' . getpid()

" Resolved while sourcing: inside a function <sfile> names the function, not
" the file it came from.
let s:testdir = expand('<sfile>:p:h')

" The plugin under test: the parent of test/.
let g:vf90_plugin_root = fnamemodify(s:testdir, ':h')

function! Vf90Mkdir(path) abort
  if !isdirectory(a:path)
    call mkdir(a:path, 'p')
  endif
  return a:path
endfunction

" A unique, empty directory for the calling test.
function! Vf90Fixture(name) abort
  let s:counter = get(s:, 'counter', 0) + 1
  let l:dir = g:vf90_scratch . '/' . a:name . '_' . s:counter
  call delete(l:dir, 'rf')
  return Vf90Mkdir(l:dir)
endfunction

function! Vf90Write(path, lines) abort
  call Vf90Mkdir(fnamemodify(a:path, ':h'))
  call writefile(type(a:lines) == v:t_list ? a:lines : split(a:lines, "\n", 1), a:path)
  return a:path
endfunction

" Copy one of the committed fixtures in test/fixtures into a writable dir.
function! Vf90CopyFixture(name, dest) abort
  let l:src = s:testdir . '/fixtures/' . a:name
  call Vf90Mkdir(a:dest)
  for l:file in glob(l:src . '/**/*', 0, 1) + glob(l:src . '/*', 0, 1)
    if !isdirectory(l:file)
      let l:rel = strpart(l:file, len(l:src) + 1)
      call Vf90Write(a:dest . '/' . l:rel, readfile(l:file))
    endif
  endfor
  return a:dest
endfunction

" The stand-in REPL process. Distinctly named so that a leftover is
" unmistakably ours: cleaning up stray `cat` processes can hit anything.
function! Vf90ReplStub() abort
  return s:testdir . '/fixtures/bin/vf90-repl-stub'
endfunction

" Stub processes currently running. The bracket around the first character
" keeps pgrep from matching the shell that runs the pgrep.
function! s:running_stubs() abort
  if !executable('pgrep')
    return []
  endif
  let l:out = system("pgrep -f '[v]f90-repl-stub'")
  if v:shell_error > 1
    return []
  endif
  return filter(split(l:out, "\n"), '!empty(trim(v:val))')
endfunction

" Stubs that were already running before the suite started. Anything in here
" belongs to someone else -- an earlier aborted run, a second suite running in
" parallel -- and must not be blamed on, or killed by, this one.
let s:stub_baseline = []

function! Vf90MarkStubBaseline() abort
  let s:stub_baseline = s:running_stubs()
  return s:stub_baseline
endfunction

" Processes this run started and failed to reap.
"
" Two things make a naive check flaky. A job stopped a moment ago is still on
" its way out, because job_stop() delivers a signal and returns, so an
" immediate look races the kernel. And a stray from an earlier run would be
" reported against this one. Hence a settling period, and the baseline.
function! Vf90LeakedProcesses(...) abort
  let l:grace = a:0 > 0 ? a:1 : 1000
  let l:waited = 0
  while 1
    let l:pids = filter(s:running_stubs(), 'index(s:stub_baseline, v:val) < 0')
    if empty(l:pids) || l:waited >= l:grace
      return l:pids
    endif
    sleep 100m
    let l:waited += 100
  endwhile
endfunction

function! Vf90KillLeaked() abort
  for l:pid in Vf90LeakedProcesses()
    call system('kill -9 ' . shellescape(trim(l:pid)) . ' 2>/dev/null')
  endfor
endfunction

" Record how far a test has got, for pinpointing a hang that only happens
" somewhere else. run.sh prints this when the watchdog fires.
function! Vf90Mark(text) abort
  if exists('g:vf90_current')
    call writefile([a:text], g:vf90_current)
  endif
endfunction

" Abandon the current test without failing it. Used when a test needs a tool
" that is not installed, and for behaviour that is a known, documented gap.
function! Vf90Skip(reason) abort
  throw 'VF90SKIP:' . a:reason
endfunction

function! Vf90NeedExecutable(name) abort
  if !executable(a:name)
    call Vf90Skip(a:name . ' is not installed')
  endif
endfunction

" Open a throwaway buffer holding the given lines, as a real file so that
" expand('%:p') and friends behave the way the plugin expects.
function! Vf90OpenScratch(path, lines) abort
  call Vf90Write(a:path, a:lines)
  execute 'silent edit! ' . fnameescape(a:path)
  return bufnr('%')
endfunction

" Drop every buffer so one test cannot leak state into the next.
function! Vf90Wipe() abort
  for l:b in range(1, bufnr('$'))
    if bufexists(l:b)
      if has('nvim')
        let l:job = getbufvar(l:b, 'terminal_job_id', 0)
        if l:job > 0
          silent! call chanclose(l:job)
          silent! call jobstop(l:job)
        endif
      elseif exists('*term_getjob')
        let l:job = term_getjob(l:b)
        if l:job isnot v:null && job_status(l:job) ==# 'run'
          silent! call job_stop(l:job)
        endif
      endif
    endif
  endfor
  silent! only!
  for l:b in range(1, bufnr('$'))
    if bufexists(l:b)
      silent! execute 'bwipeout! ' . l:b
    endif
  endfor
endfunction

" Wait until Cond evaluates true, or the timeout expires. Returns success.
" Async builds finish on their own schedule; polling beats a fixed sleep.
function! Vf90WaitFor(Cond, ...) abort
  let l:timeout = a:0 > 0 ? a:1 : 10000
  let l:waited = 0
  while l:waited < l:timeout
    if call(a:Cond, [])
      return 1
    endif
    sleep 50m
    let l:waited += 50
  endwhile
  return call(a:Cond, [])
endfunction

" Reset the globals the plugin reads, so tests start from documented defaults.
function! Vf90ResetOptions() abort
  for l:name in ['fortran_profile', 'fortran_compiler', 'fortran_async',
        \ 'fortran_openmp', 'fortran_mpi', 'fortran_gpu', 'fortran_extra_flags',
        \ 'fortran_project_root', 'fortran_repl_command', 'fortran_qf_auto_close',
        \ 'Fortran_root_provider', 'fortran_root_provider',
        \ 'Fortran_build_provider', 'fortran_build_provider']
    if exists('g:' . l:name)
      execute 'unlet g:' . l:name
    endif
  endfor
endfunction
