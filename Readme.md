# vimf90

A modern development environment for scientific and high-performance Fortran (F90, F95, F2003, F2008, F2018, F2023) in Vim and Neovim.

---

## ⟠ Why vimf90: it teaches your language server about `fpm`

Nothing in the Vim ecosystem understands Fortran Package Manager projects. `fortls` has no `fpm` awareness at all — its default `source_dirs` is `./**`, so on an `fpm` project it recurses straight into `build/` and indexes a copy of your entire source tree for **every** `build/<compiler>_<hash>/` directory `fpm` has ever produced. One project, six profiles, six duplicate definitions of every module. `nvim-lspconfig` does not list `fpm.toml` as a root marker either.

**`vimf90` generates a correct `.fortls` for you**, and keeps it current:

```json
{
  "_generated_by": "vimf90",
  "source_dirs": ["app", "src", "src/utils", "test",
                  "build/dependencies/mydep/src"],
  "excl_paths": ["build", ".git"]
}
```

Every source directory is enumerated by name, dependency sources stay reachable, and no build directory is ever listed. Measured on a project with six hash directories, the indexed set drops from eleven directories to six, with zero duplicate module symbols.

The detail that makes this worth automating: `fortls` does **not** recurse into explicitly configured `source_dirs`, so a nested `src/utils` is invisible unless it is named — and its `excl_paths` is exact string matching, not globbing, so the `"build/**"` you would naturally write silently matches nothing and changes nothing. Getting this right by hand, and keeping it right as directories come and go, is exactly the kind of job an editor plugin should do for you.

It also means **`fpm`'s hash churn stops mattering**. Because no `build/<compiler>_<hash>` path is ever written into the manifest, a new one appearing changes nothing, and there is nothing to track. Regeneration is driven by source directories changing — on `:FortranFpmBuild`, on writing `fpm.toml`, or on demand with `:FortranFortlsConfig`.

A hand-written `.fortls` is never touched: without the `_generated_by` marker, your file wins.

---

## ◈ Overview & Key Features

* ⟠ **Automatic `fortls` Project Configuration**: Generates and maintains a correct `.fortls` from your `fpm` layout, so the language server indexes your sources and your dependencies — and never the `build/` tree. See [above](#-why-vimf90-it-teaches-your-language-server-about-fpm).
* ◈ **Fortran Package Manager (`fpm`)**: Full asynchronous execution for `fpm build`, `fpm run`, `fpm test`, `fpm-test-current`, and `fpm new`.
* ⚗ **Interactive LFortran REPL**: Integrated REPL workflow (`:FortranReplToggle` / `<leader>rt`) to send lines (`<leader>rs`), visual selections, enclosing subprograms (`<leader>rm`), or whole buffers (`<leader>rb`) directly to [LFortran](https://lfortran.org/).
* ⧉ **Scientific Scratchpad**: Ephemeral prototyping buffer (`:FortranScratch` / `<leader>so`) with scientific templates (`program`, `matrix`, `openmp`, `module`, `test`) and instant execution (`:FortranScratchRun` / `<leader>sr`).
* ⌕ **Multi-File Project Resolution**: Automatic project root detection, multi-directory module and include path discovery (`-I`), and cross-file module navigation (`:FortranFindModule`).
* ⚡ **Asynchronous Build Engine**: Non-blocking background compilation for Vim 8/9 & Neovim with multi-compiler QuickFix error parsing (`gfortran`, `ifx`, `ifort`, `nvfortran`, `flang`).
* ⎇ **Semantic Text Objects & Motions**: Domain-aware text objects (`vaf`/`vif` subprogram, `vam`/`vim` module, `vat`/`vit` derived type, `vad`/`vid` loop) and subprogram jumps (`]m`, `[m`, `]M`, `[M`) — in free form and in [fixed form](#-fixed-source-form-fortran-77) alike, including bare `END` and labelled `DO` loops.
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

The manifest is generated for you — see [Why vimf90](#-why-vimf90-it-teaches-your-language-server-about-fpm). All that remains is pointing your LSP client at the project. Put `fpm.toml` **first** in the root patterns: it is present before the first build, whereas `.fortls` only appears once `vimf90` has written it.

For `coc.nvim`, add to `coc-settings.json`:
```json
{
  "languageserver": {
    "fortran": {
      "command": "fortls",
      "args": ["--lowercase_intrinsics"],
      "filetypes": ["fortran"],
      "rootPatterns": ["fpm.toml", ".fortls", ".git/"]
    }
  }
}
```

For Neovim native LSP (`nvim-lspconfig`):
```lua
require('lspconfig').fortls.setup{
  cmd = { "fortls", "--lowercase_intrinsics" },
  root_dir = require('lspconfig.util').root_pattern("fpm.toml", ".fortls", ".git")
}
```

Rooting the server correctly matters as much as scoping it: `nvim-lspconfig`'s default markers for `fortls` are `.fortls` and `.git`, and with neither nearby the server can end up rooted somewhere very large.

| Setting | Default | Effect |
|---|---|---|
| `g:fortran_fortls_autoconfig` | `1` | Set to `0` to never write `.fortls` automatically. `:FortranFortlsConfig` still works on demand. |

---

## ⌗ Fixed Source Form (FORTRAN 77)

Fixed-form sources are supported by the structural features, not merely tolerated. Source form is decided the way Vim's own `fortran` ftplugin decides it, so no extra configuration is needed:

1. `b:fortran_fixed_source` — what the bundled ftplugin leaves behind, including its content sniffing for ambiguous extensions
2. `g:fortran_fixed_source` / `g:fortran_free_source`
3. the file extension: `.f`, `.for`, `.f77`, `.ftn` are fixed form, any case

### What works

| | Fixed form |
|---|---|
| `af` / `if` subprogram | `PROGRAM`, `SUBROUTINE`, `FUNCTION`, `BLOCK DATA` |
| Typed functions | `REAL FUNCTION F(X)`, `INTEGER*4 FUNCTION N()`, `DOUBLE PRECISION FUNCTION` |
| Unit termination | bare `END`, and `END SUBROUTINE`/`END FUNCTION`/`END PROGRAM` with or without a trailing name |
| `ad` / `id` loop | labelled `DO 10 ... 10 CONTINUE`, **and** `DO ... END DO` |
| Labelled loop terminator | any executable statement carrying the label, not just `CONTINUE` |
| Nested and shared terminators | `DO 10` / `DO 10` closing on one `10 CONTINUE` resolves for both loops |
| `am` / `im`, `at` / `it`, `ab` / `ib` | `MODULE`, `TYPE`, `INTERFACE`, `BLOCK` in fixed-form Fortran 90+ |
| Motions | `]m`, `[m`, `]M`, `[M` across fixed-form program units |
| Statement labels | columns 1–5 are skipped when matching a construct |
| Comments | `C`, `c` and `*` in column one, plus `!` |
| Continuation lines | a non-blank in column six continues the statement above and can neither open nor close a construct |
| `:FortranReplSendSubprogram` | follows the fixed-form unit boundaries |
| `:FortranFindModule` | searches `.f`, `.for`, `.f77`, `.ftn` alongside free-form sources |
| Build, run, compile, profiles | unchanged — these are compiler invocations and never depended on source form |

### What does not

* **Column 73 onwards is not truncated.** Historically anything past column 72 is ignored by the compiler; `vimf90` reads the whole line, so a construct keyword parked in the card-identification field would be seen when the compiler would not see it.
* **`ENTRY` is not a construct start.** An alternate entry point sits inside its enclosing unit rather than beginning one of its own.
* **Arithmetic `IF` and statement functions** are not tracked. They are statements, not block constructs, and there is no region to select.
* **`.f90` and friends are free form regardless of content.** If you keep fixed-form code in a free-form extension, set `b:fortran_fixed_source = 1` (or `g:fortran_fixed_source`) and everything above applies.

---

## ⚑ Testing

The suite is plain Vimscript with no external dependencies, built on Vim's own `assert_*` family:

```sh
sh test/run.sh                       # everything
sh test/run.sh textobj project       # selected files
VF90_TEST=Test_name sh test/run.sh   # a single test
VF90_VIM=nvim sh test/run.sh         # against Neovim
VF90_TIMEOUT=600 sh test/run.sh      # raise the 300s watchdog (0 disables)
```

A watchdog kills the editor after `VF90_TIMEOUT` seconds and says so, and the suite fails if it finds a process it started and did not reap. Both exist because a wedged run once left nine headless Neovim instances running for over an hour, unnoticed. The REPL tests spawn `test/fixtures/bin/vf90-repl-stub` rather than `cat`, so a leftover is identifiable by name and can never be confused with something else on the machine.

It exits non-zero on failure, so it drops straight into CI. Tests that need `gfortran`, `fpm`, `fortls` or `luac` skip themselves when the tool is absent rather than failing. The suite is green on both Vim 9.2 and Neovim 0.12.

The editor variable is `VF90_VIM` rather than `VIM` on purpose: `$VIM` is Vim's own variable for locating `$VIMRUNTIME`, so exporting `VIM=nvim` sets `$VIMRUNTIME` to `nvim` and quietly breaks filetype detection along with every other runtime file — the editor still starts and still runs the tests, they just fail for reasons that have nothing to do with your change.

| File | Covers |
|---|---|
| `test_textobj.vim` | construct boundaries, typed function declarations, motions |
| `test_project.vim` | root detection, include paths, module search, delegation hooks |
| `test_fortls.vim` | generated manifests, checked against real `fortls` output |
| `test_makes.vim` | compiling, linking, and how build status is decided |
| `test_repl.vim` | REPL lifecycle, restart, sending text |
| `test_fpm.vim` | project discovery, targets, completion, build hooks |
| `test_doc.vim` | FORD configuration and the preview flow |
| `test_plugin.vim` | loading, commands, mappings, autocommands, embedded Lua |

`test_plugin.vim` is worth knowing about: it guards against the failure mode where code is never reachable at all — an autoload file shadowing another plugin, an autocommand registered where it cannot fire, embedded Lua that never parses, `\b` used as a word boundary (Vim reads it as a backspace), or a Funcref assigned to a lowercase name (`E704`).

---

## ⚖ License

GPLv3. Copyright (C) Rudra Banerjee.
