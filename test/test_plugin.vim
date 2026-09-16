"########################################################################
" test_plugin.vim — wiring: does everything load, and are the commands,
" mappings and autocommands actually there.
"
" A surprising share of this plugin's breakage has been things that were never
" reachable at all: a function in a file that shadowed another plugin, an
" autocommand registered somewhere it could not fire, Lua that never parsed.
"########################################################################

function! Test_every_autoload_file_sources_cleanly() abort
  let l:root = fnamemodify(g:vf90_plugin_root, ':p')
  for l:file in glob(l:root . '/autoload/*.vim', 0, 1)
    try
      execute 'source ' . fnameescape(l:file)
    catch
      call assert_report(fnamemodify(l:file, ':t') . ' failed to source: ' . v:exception)
    endtry
  endfor
endfunction

" autoload/tagbar.vim would shadow the Tagbar plugin's own file of that name,
" and whichever came first on the runtimepath would break the other.
function! Test_no_autoload_file_shadows_a_known_plugin() abort
  let l:root = fnamemodify(g:vf90_plugin_root, ':p')
  for l:reserved in ['tagbar.vim', 'fugitive.vim', 'ale.vim', 'lsp.vim']
    call assert_equal(0, filereadable(l:root . '/autoload/' . l:reserved),
          \ 'autoload/' . l:reserved . ' collides with another plugin')
  endfor
endfunction

function! Test_fortran_buffer_defines_core_commands() abort
  let l:dir = Vf90Fixture('plugin')
  call Vf90OpenScratch(l:dir . '/a.f90', ['program a', 'end program a'])
  setlocal filetype=fortran
  for l:name in ['FortranCompile', 'FortranRun', 'FortranProjectBuild',
        \ 'FortranFortlsConfig', 'FortranReplToggle', 'FortranFindModule']
    call assert_equal(2, exists(':' . l:name), l:name . ' is missing')
  endfor
endfunction

function! Test_fortran_buffer_defines_plug_mappings() abort
  let l:dir = Vf90Fixture('plugin')
  call Vf90OpenScratch(l:dir . '/a.f90', ['program a', 'end program a'])
  setlocal filetype=fortran
  let l:maps = execute('nmap <buffer>')
  for l:name in ['vimf90-compile', 'vimf90-run', 'vimf90-repl-toggle']
    call assert_match(l:name, l:maps, '<Plug>(' . l:name . ') is missing')
  endfor
endfunction

" The visual send must not eat its own range: a :<C-U> in the mapping would
" delete the '<,'> that carries the selection.
function! Test_visual_repl_mapping_keeps_its_range() abort
  let l:dir = Vf90Fixture('plugin')
  call Vf90OpenScratch(l:dir . '/a.f90', ['program a', 'end program a'])
  setlocal filetype=fortran
  let l:map = execute('xmap <Plug>(vimf90-repl-send-visual)')
  " Assert the mapping exists first: 'No mapping found' contains no <C-U>
  " either, so the check below would otherwise pass for the wrong reason.
  call assert_match('repl#send_visual', l:map, 'the mapping is not defined at all')
  call assert_notmatch('<C-U>', l:map, 'the mapping discards the visual range')
endfunction

" The manifest watcher has to exist in a session where no Fortran file was
" ever opened: adding a dependency means editing fpm.toml on its own.
function! Test_manifest_autocmd_exists_without_a_fortran_buffer() abort
  let l:autocmds = execute('autocmd vimf90_fpm_manifest')
  call assert_match('fpm.toml', l:autocmds, 'no BufWritePost watcher for fpm.toml')
endfunction

function! Test_manifest_watcher_can_be_disabled() abort
  call assert_equal(1, get(g:, 'fortran_fortls_autoconfig', 1),
        \ 'the opt-out should default to on')
endfunction

" Embedded Lua is invisible to Vim until it runs, so a syntax error there sits
" undetected. Parse each heredoc with luac when it is available.
function! Test_embedded_lua_parses() abort
  call Vf90NeedExecutable('luac')
  let l:root = fnamemodify(g:vf90_plugin_root, ':p')
  for l:file in glob(l:root . '/autoload/*.vim', 0, 1)
    let l:lines = readfile(l:file)
    let l:chunk = []
    let l:inside = 0
    let l:start = 0
    for l:i in range(len(l:lines))
      if !l:inside && l:lines[l:i] =~# '^\s*lua\s*<<\s*\S\+\s*$'
        let l:inside = 1
        let l:start = l:i + 1
        let l:chunk = []
      elseif l:inside && l:lines[l:i] =~# '^\S\+$' && l:lines[l:i] !~# '^\s'
        let l:tmp = tempname() . '.lua'
        call writefile(l:chunk, l:tmp)
        call system('luac -p ' . shellescape(l:tmp))
        call assert_equal(0, v:shell_error,
              \ fnamemodify(l:file, ':t') . ' line ' . l:start . ': Lua does not parse')
        call delete(l:tmp)
        let l:inside = 0
      elseif l:inside
        call add(l:chunk, l:lines[l:i])
      endif
    endfor
    call assert_equal(0, l:inside, fnamemodify(l:file, ':t') . ': unterminated lua heredoc')
  endfor
endfunction

" Vim regex has no \b: it means a backspace character, and a word boundary is
" \< or \>. A stray \b silently matches nothing.
function! Test_no_backspace_escape_in_patterns() abort
  let l:root = fnamemodify(g:vf90_plugin_root, ':p')
  for l:file in glob(l:root . '/autoload/*.vim', 0, 1) + glob(l:root . '/ftplugin/*.vim', 0, 1)
    let l:n = 0
    for l:line in readfile(l:file)
      let l:n += 1
      if l:line =~# "'[^']*\\\\b[^']*'" && l:line !~# '^\s*"'
        call assert_report(fnamemodify(l:file, ':t') . ':' . l:n
              \ . ' uses \b in a pattern; Vim reads that as a backspace, not a word boundary')
      endif
    endfor
  endfor
endfunction

" A Funcref cannot live in a lowercase-named variable (E704), so an assignment
" of a:1 or a get() result to one is a latent crash on the callback path.
function! Test_no_lowercase_funcref_assignments() abort
  let l:root = fnamemodify(g:vf90_plugin_root, ':p')
  for l:file in glob(l:root . '/autoload/*.vim', 0, 1)
    let l:n = 0
    for l:line in readfile(l:file)
      let l:n += 1
      if l:line =~# '\<let\s\+l:[a-z]\w*\s*=.*\<\%(on_finish\|callback\|provider\)\>'
        call assert_report(fnamemodify(l:file, ':t') . ':' . l:n
              \ . ' assigns a callback to a lowercase name; Vim raises E704')
      endif
    endfor
  endfor
endfunction
