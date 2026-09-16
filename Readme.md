# vimf90

A modern development environment for scientific and high-performance Fortran (F90, F95, F2003, F2008, F2018, F2023) in Vim and Neovim.

---

## ◈ Overview & Key Features

* ◈ **Fortran Package Manager (`fpm`)**: Full asynchronous execution for `fpm build`, `fpm run`, `fpm test`, `fpm-test-current`, and `fpm new`.
* ⚗ **Interactive LFortran REPL**: Integrated REPL workflow (`:FortranReplToggle` / `<leader>rt`) to send lines (`<leader>rs`), visual selections, enclosing subprograms (`<leader>rm`), or whole buffers (`<leader>rb`) directly to [LFortran](https://lfortran.org/).
* ⧉ **Scientific Scratchpad**: Ephemeral prototyping buffer (`:FortranScratch` / `<leader>so`) with scientific templates (`program`, `matrix`, `openmp`, `module`, `test`) and instant execution (`:FortranScratchRun` / `<leader>sr`).
* ⌕ **Multi-File Project Resolution**: Automatic project root detection, multi-directory module and include path discovery (`-I`), and cross-file module navigation (`:FortranFindModule`).
* ⚡ **Asynchronous Build Engine**: Non-blocking background compilation for Vim 8/9 & Neovim with multi-compiler QuickFix error parsing (`gfortran`, `ifx`, `ifort`, `nvfortran`, `flang`).
* ⎇ **Semantic Text Objects & Motions**: Domain-aware text objects (`vaf`/`vif` subprogram, `vam`/`vim` module, `vat`/`vit` derived type, `vad`/`vid` loop) and subprogram jumps (`]m`, `[m`, `]M`, `[M`).
* ✎ **FORD Documentation Engine**: Automated docstring generator (`:FortranDoc` / `<leader>dc`) with parameter type, `intent(in/out/inout)`, and attribute deduction, plus asynchronous project documentation building and browser preview (`:FordBuild`, `:FordPreview`).
* ⚙ **HPC & Compilation Profiles**: Switchable presets for `Debug`, `Release`, `Fast`, and `Sanitize`, with OpenMP multithreading, MPI wrappers, and native ISO Coarray Fortran support (`:FortranProfile`, `:FortranOpenMP`, `:FortranMPI`).
* ⨁ **Accelerators & Supercomputing**: GPU offloading (`:FortranGPU` OpenACC/OpenMP Target) and MPI cluster job execution (`:FortranMPIRun`).
* ⌖ **Scientific Debugging & Matrix Inspector**: GDB/LLDB/Termdebug and `nvim-dap` integration with breakpoint toggles (`:FortranBreakpointToggle`) and live multi-dimensional array visualization (`:FortranInspectArray` / `<leader>da`).
* ☰ **Symbol Hierarchy**: Universal Ctags symbol tree (`Program` &rarr; `Module` &rarr; `Type` &rarr; `Interface` &rarr; `Subroutine`) compatible with `tagbar` and `aerial.nvim`.
* ⛊ **Buffer-Local Hygiene**: All mappings and settings are strictly buffer-scoped with complete `b:undo_ftplugin` teardown.

---

## ⬡ Installation

### vim-plug
```vim
Plug 'rudrab/vimf90'
```

### packer.nvim
```lua
use 'rudrab/vimf90'
```

### lazy.nvim
```lua
{ 'rudrab/vimf90', ft = 'fortran' }
```

---

## ⚗ Recommended Ecosystem & Companion Tools

`vimf90` handles build orchestration, diagnostics parsing, project navigation, text objects, and docstrings, integrating cleanly with standard tools in the Vim/Neovim ecosystem:

| Tool | Category | Status | Description |
|---|---|:---:|---|
| [**fpm**](https://fpm.fortran-lang.org/) | Package Manager | Recommended | Standard Fortran package manager and build system. |
| [**LFortran**](https://lfortran.org/) | Interactive REPL | Recommended | Interactive Fortran compiler and REPL backend. |
| [**fortls**](https://github.com/gnikit/fortls) | Language Server | Recommended | Language Server for hover docs, signature help, and completion. |
| [**fprettify**](https://github.com/pseewald/fprettify) | Formatter | Recommended | Source code auto-formatting (`:FortranFormat` or on save). |
| [**vim-snippets**](https://github.com/honza/vim-snippets) | Snippets | Recommended | Standard snippets for [LuaSnip](https://github.com/L3MON4D3/LuaSnip) or [UltiSnips](https://github.com/SirVer/ultisnips). |
| [**tagbar**](https://github.com/majutsushi/tagbar) / [**aerial.nvim**](https://github.com/stevearc/aerial.nvim) | Symbol Outline | Recommended | Hierarchical code outliner (auto-configured by `vimf90`). |
| [**coc.nvim**](https://github.com/neoclide/coc.nvim) / **nvim-lspconfig** | LSP Client | Recommended | LSP client integration for `fortls`. |
| [**vim-endwise**](https://github.com/tpope/vim-endwise) | Editing | Optional | Automatically inserts matching `end` statements. |

---

## ⌨ Key Mappings

All mappings are buffer-local and respect `g:fortran_leader` (defaults to `<Leader>` or `\`):

| Mapping | Target | Action |
|---|---|---|
| `<leader>cc` | `<Plug>(vimf90-compile)` | Compile current file to object file (`.o`) |
| `<leader>ce` | `<Plug>(vimf90-exe)` | Build executable |
| `<leader>cr` | `<Plug>(vimf90-run)` | Build and run current buffer |
| `<leader>cl` | `<Plug>(vimf90-cla)` | Set command line arguments for execution |
| `<leader>cd` | `<Plug>(vimf90-dbg)` | Debug executable (`gdb`/`lldb`) |
| `<leader>fb` | `<Plug>(vimf90-fpm-build)` | `fpm build` project asynchronously |
| `<leader>fr` | `<Plug>(vimf90-fpm-run)` | `fpm run` application |
| `<leader>ft` | `<Plug>(vimf90-fpm-test)` | `fpm test` all unit tests |
| `<leader>tc` | `<Plug>(vimf90-fpm-test-current)` | `fpm test` current test file / target under cursor |
| `<leader>rt` | `<Plug>(vimf90-repl-toggle)` | Toggle interactive LFortran REPL terminal |
| `<leader>rs` | `<Plug>(vimf90-repl-send-line)` | Send current line (or visual selection) to REPL |
| `<leader>rm` | `<Plug>(vimf90-repl-send-subprog)` | Send enclosing subprogram / module to REPL |
| `<leader>rb` | `<Plug>(vimf90-repl-send-buffer)` | Send entire buffer to REPL |
| `<leader>so` | `<Plug>(vimf90-scratch-open)` | Open scientific Fortran scratchpad buffer |
| `<leader>sr` | `<Plug>(vimf90-scratch-run)` | Compile & run scientific scratchpad buffer |
| `<leader>tg` | `<Plug>(vimf90-tags)` | Generate project Universal Ctags |
| `<leader>fm` | `<Plug>(vimf90-find-module)` | Find & jump to module definition across project |
| `<leader>dc` | `<Plug>(vimf90-doc)` | Generate FORD / Doxygen docstring header |
| `<leader>db` | `<Plug>(vimf90-ford-build)` | Build project FORD documentation (`:FordBuild`) |
| `<leader>dp` | `<Plug>(vimf90-ford-preview)` | Preview FORD documentation in browser (`:FordPreview`) |
| `<leader>pp` | `<Plug>(vimf90-profile)` | Switch / show compilation profile |
| `<leader>po` | `<Plug>(vimf90-openmp)` | Toggle OpenMP multithreading |
| `<leader>pm` | `<Plug>(vimf90-mpi)` | Toggle MPI compiler wrapper |
| `<leader>pg` | `<Plug>(vimf90-gpu-toggle)` | Toggle GPU Offload (OpenACC / OpenMP Target) |
| `<leader>pr` | `<Plug>(vimf90-mpi-run)` | Launch MPI multi-rank cluster execution (`mpirun`) |
| `<leader>da` | `<Plug>(vimf90-inspect-array)` | Inspect multi-dimensional array / matrix structure |
| `<leader>dt` | `<Plug>(vimf90-breakpoint-toggle)` | Toggle debug breakpoint on current line |
| `<leader>mk` | `<Plug>(vimf90-make)` | Run `make` (historical fallback) |
| `<leader>mp` | `<Plug>(vimf90-makeprop)` | Set `make` target / properties |

### Text Objects & Motions
* **Text Objects** (`v` visual mode, `d`/`y`/`c` operator mode):
  * `af` / `if`: Around / inside `subroutine` or `function`
  * `am` / `im`: Around / inside `module` or `program`
  * `at` / `it`: Around / inside derived `type` definition
  * `ad` / `id`: Around / inside `do` loop
  * `ab` / `ib`: Around / inside `block` or `interface`
* **Structural Motions**:
  * `]m` / `[m`: Jump to next / previous subprogram header
  * `]M` / `[M`: Jump to next / previous `end subroutine` / `end function`

---

## ⚙ User Commands

* **Supercomputing, HPC & Parallel Standards**:
  * `:FortranGPU [openmp|openacc|off]`: Configure GPU offloading flags.
  * `:FortranMPIRun [ranks] [args]`: Launch executable with `mpirun -n <ranks>` in terminal.
* **Scientific Debugging & DAP**:
  * `:FortranInspectArray [var] [rows] [cols]`: Formatted 2D matrix inspector for arrays.
  * `:FortranBreakpointToggle`: Toggle breakpoint on current line for GDB / DAP.
  * `:FortranTermdebug [exe]`: Start native Vim `Termdebug` session.
  * `:FortranDapStart`: Launch `nvim-dap` debug session.
* **Interactive REPL & Scratchpad**:
  * `:FortranReplToggle` / `:FortranReplOpen [cmd]`: Open or focus LFortran REPL terminal split.
  * `:FortranReplSend`: Send visual selection or line to REPL.
  * `:FortranReplSendSubprogram`: Send current subroutine, function, or module to REPL.
  * `:FortranReplSendBuffer`: Send entire active buffer to REPL.
  * `:FortranReplRestart`: Restart the active REPL session.
  * `:FortranScratch [program|matrix|openmp|module|test]`: Open ephemeral scientific scratchpad.
  * `:FortranScratchRun`: Compile, execute, and display output of the scratchpad buffer.
* **Fortran Package Manager (`fpm`) & LSP Synchronization**:
  * `:FortranFpm [subcmd]` / `:FortranFpmBuild` / `:FortranFpmRun [target]` / `:FortranFpmTest [target]`
  * `:FortranFpmTestCurrent`: Run only the unit test in the active buffer.
  * `:FortranFpmAdd <dependency>`: Add standard dependency (`stdlib`, `test-drive`, `lapack`, `toml-f`) to `fpm.toml`.
  * `:FortranFpmNew <name>`: Scaffold a new standard Fortran package and initialize `.fortls`.
  * `:FortranFortlsConfig`: Synchronize `.fortls` LSP config directly from fpm layout and dependencies (isolating `fortls` from compiler hash churn in `build/`).
* **FORD Documentation**:
  * `:FortranDoc [ford|doxygen]`: Generate documentation header for subroutine, function, module, type, or interface.
  * `:FordBuild`: Build project FORD documentation asynchronously.
  * `:FordPreview`: Build & open project documentation in default web browser.
* **Project Navigation & Delegation**:
  * `:FortranProjectBuild` / `:FortranProjectRoot` / `:FortranTags` / `:FortranFindModule <name>`
  * Extract exact `-I` & `-J` module paths automatically from `build/compile_commands.json`.
  * Custom root delegation: `b:fortran_project_root`, `g:fortran_project_root`, `g:Fortran_root_provider`.
  * External build runner delegation: `g:Fortran_build_provider` (for `vim-dispatch` or `asyncrun.vim`).
* **Compiler & HPC Profiles**:
  * `:FortranCompile` / `:FortranExe` / `:FortranRun` / `:FortranArgs` / `:FortranDebug`
  * `:FortranProfile [debug|release|fast|sanitize]`
  * `:FortranCompiler [gfortran|ifx|ifort|nvfortran|flang]`
  * `:FortranOpenMP [on|off|toggle]` / `:FortranMPI [on|off|toggle]`
* **Formatting**:
  * `:FortranFormat` (Delegates to `fprettify`)
  * `:FortranInstallDeps` (Advisory dependency helper)

---

## ⛭ Configuration & Delegation Hooks

Add optional settings to `.vimrc` or `init.lua`:

```vim
" Custom leader for Fortran mappings (defaults to mapleader or '\')
let g:fortran_leader = '\'

" Active compiler backend ('gfortran', 'ifx', 'ifort', 'nvfortran', 'flang')
let g:fortran_compiler = 'gfortran'

" Active build profile ('debug', 'release', 'fast', 'sanitize')
let g:fortran_profile = 'debug'

" Enable async execution (Vim 8/9 & Neovim)
let g:fortran_async = 1

" Auto format buffer on save via fprettify (0: off, 1: on)
let g:fortran_format_on_save = 0

" Default docstring style ('ford' or 'doxygen')
let g:fortran_doc_style = 'ford'

" Pluggable root provider (e.g. integrate with project.nvim / vim-rooter)
" let g:Fortran_root_provider = {-> FindProjectRoot()}

" Pluggable build provider (e.g. delegate builds to asyncrun or vim-dispatch)
" let g:Fortran_build_provider = {opts -> DispatchBuild(opts)}

" Statusline helper: returns e.g. '[gfortran:Debug:OMP:MPI]'
" statusline=%<%f\ %h%m%r%=%{profiles#status()}\ %-14.(%l,%c%V%)\ %P
```

---

## ⟠ Language Server Protocol (`fortls`) Setup

`vimf90` automatically generates and maintains a lean, optimized `.fortls` file in your `fpm` project root. It explicitly enumerates all project source directories and dependencies (`build/dependencies/*/src`) while completely excluding `build/` and `.git/`. This eliminates module definition duplication and keeps `fortls` blazing fast.

For `coc.nvim`, add to `coc-settings.json`:
```json
{
  "languageserver": {
    "fortran": {
      "command": "fortls",
      "args": ["--lowercase_intrinsics"],
      "filetypes": ["fortran"],
      "rootPatterns": [".fortls", "fpm.toml", ".git/"]
    }
  }
}
```

For Neovim native LSP (`nvim-lspconfig`):
```lua
require('lspconfig').fortls.setup{
  cmd = { "fortls", "--lowercase_intrinsics" },
  root_dir = require('lspconfig.util').root_pattern(".fortls", "fpm.toml", ".git")
}
```

---

## ⚖ License

GPLv3. Copyright (C) Rudra Banerjee.
