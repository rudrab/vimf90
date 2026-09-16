"########################################################################
" File:          autoload/dap.vim
" Author:        Rudra Banerjee (bnrj DOT rudra at gmail.com)
" License:       GPLv3
" Description:   Scientific Debugging (DAP, Termdebug) and Multi-Dimensional
"                Array Inspector for Computational Fortran
"########################################################################

let s:save_cpo = &cpo
set cpo&vim

let s:array_win_bufnr = -1

function! dap#setup() abort
  if has('nvim')
    lua << EOF
    local ok, dap = pcall(require, 'dap')
    if ok then
      if not dap.adapters.gdb then
        dap.adapters.gdb = {
          type = "executable",
          command = "gdb",
          args = { "-i", "dap" }
        }
      end
      if not dap.adapters.codelldb then
        dap.adapters.codelldb = {
          type = 'server',
          port = "${port}",
          executable = {
            command = 'codelldb',
            args = {"--port", "${port}"},
          }
        }
      end
      dap.configurations.fortran = dap.configurations.fortran or {
        {
          name = "Launch Fortran Executable (GDB)",
          type = "gdb",
          request = "launch",
          program = function()
            return vim.fn.expand('%:p:r')
          end,
          cwd = '${workspaceFolder}',
          stopAtBeginningOfMainSubprogram = false,
        },
        {
          name = "Launch Fortran Executable (CodeLLDB)",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.expand('%:p:r')
          end,
          cwd = '${workspaceFolder}',
          stopOnEntry = false,
        }
      }
    end
EOF
  endif
endfunction

function! dap#start() abort
  let l:exeext = makes#get_opt('fortran_exeExt', '')
  let l:exe = expand('%:p:r') . l:exeext
  if !filereadable(l:exe)
    let l:built = makes#Fexe(0)
    if !l:built
      return
    endif
  endif

  if has('nvim')
    call dap#setup()
    let l:has_dap = 0
    lua << EOF
    local ok, dap = pcall(require, 'dap')
    if ok then
      vim.g.vimf90_has_dap = 1
      dap.continue()
    else
      vim.g.vimf90_has_dap = 0
    end
EOF
    if get(g:, 'vimf90_has_dap', 0)
      return
    endif
  endif

  " Fallback to Termdebug
  call dap#termdebug(l:exe)
endfunction

function! dap#termdebug(...) abort
  let l:exe = a:0 > 0 && !empty(a:1) ? a:1 : (expand('%:p:r') . makes#get_opt('fortran_exeExt', ''))
  if !filereadable(l:exe)
    let l:built = makes#Fexe(0)
    if !l:built
      return
    endif
  endif

  if !exists(':Termdebug')
    packadd termdebug
  endif

  execute 'Termdebug ' . fnameescape(l:exe)
endfunction

function! dap#toggle_breakpoint() abort
  if has('nvim')
    let l:handled = 0
    lua << EOF
    local ok, dap = pcall(require, 'dap')
    if ok then
      dap.toggle_breakpoint()
      vim.g.vimf90_dap_bp_handled = 1
    else
      vim.g.vimf90_dap_bp_handled = 0
    end
EOF
    if get(g:, 'vimf90_dap_bp_handled', 0)
      return
    endif
  endif

  if exists(':Break')
    Break
    echomsg 'vimf90: Breakpoint set at ' . expand('%:t') . ':' . line('.')
  else
    echomsg 'vimf90: Breakpoint (line ' . line('.') . '). Start debugger with :FortranDebug or :FortranTermdebug.'
  endif
endfunction

" Multi-Dimensional Array Inspector {{{1
function! s:format_grid(elements, rows, cols) abort
  let l:out = []
  let l:header = '     | '
  for l:c in range(1, a:cols)
    let l:header .= printf('%10s ', '(:' . l:c . ')')
  endfor
  call add(l:out, l:header)
  call add(l:out, repeat('-', len(l:header)))

  let l:idx = 0
  for l:r in range(1, a:rows)
    let l:row_str = printf('%4d | ', l:r)
    for l:c in range(1, a:cols)
      if l:idx < len(a:elements)
        let l:val = a:elements[l:idx]
        let l:row_str .= printf('%10s ', l:val)
        let l:idx += 1
      else
        let l:row_str .= printf('%10s ', '-')
      endif
    endfor
    call add(l:out, l:row_str)
  endfor

  return l:out
endfunction

function! dap#inspect_array(...) abort
  let l:var = ''
  if a:0 > 0 && !empty(a:1)
    let l:var = a:1
  else
    let l:cword = expand('<cword>')
    let l:var = input('Fortran Array / Matrix variable to inspect: ', l:cword)
  endif

  if empty(l:var)
    return
  endif

  let l:rows = a:0 > 1 ? str2nr(a:2) : 5
  let l:cols = a:0 > 2 ? str2nr(a:3) : 5

  let l:cur_win = win_getid()
  let l:out_split = get(g:, 'fortran_array_inspector_split', 'botright 12split')

  if s:array_win_bufnr <= 0 || !bufexists(s:array_win_bufnr)
    execute l:out_split
    let s:array_win_bufnr = bufnr('%')
    setlocal buftype=nofile bufhidden=wipe noswapfile
    silent! file [Fortran Array Inspector]
  else
    let l:win_list = win_findbuf(s:array_win_bufnr)
    if !empty(l:win_list)
      call win_gotoid(l:win_list[0])
    else
      execute l:out_split
      execute 'buffer ' . s:array_win_bufnr
    endif
  endif

  setlocal modifiable
  silent! %delete _

  let l:lines = [
        \ '=== Scientific Fortran Array Inspector: ' . l:var . ' (' . strftime('%H:%M:%S') . ') ===',
        \ 'Shape preview: ' . l:rows . ' rows x ' . l:cols . ' cols (Column-major Fortran ordering)',
        \ ''
        \ ]

  " If GDB / Termdebug is active, query variable expression
  let l:gdb_raw = ''
  if exists(':Evaluate')
    try
      redir => l:gdb_raw
      silent execute 'Evaluate ' . l:var
      redir END
    catch
      let l:gdb_raw = ''
    endtry
  endif

  if !empty(l:gdb_raw)
    call add(l:lines, 'Debugger Output: ' . trim(l:gdb_raw))
    call add(l:lines, '')
  else
    call add(l:lines, 'Hint: Inspecting structure for variable "' . l:var . '".')
    call add(l:lines, 'Use inside an active Termdebug or DAP session for live matrix values.')
    call add(l:lines, '')
  endif

  call setline(1, l:lines)
  setlocal nomodifiable
  setlocal nonumber norelativenumber

  call win_gotoid(l:cur_win)
endfunction
"}}}1

let &cpo = s:save_cpo
unlet s:save_cpo
