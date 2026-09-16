# 🚀 VimF90 — State-of-the-Art Fortran IDE for Vim & Neovim

`vimf90` transforms Vim and Neovim into a modern, fast, and feature-rich development environment for Modern Fortran (F90, F95, F2003, F2008, F2018, F2023).

---

## 🌟 Key Features

* 📦 **First-Class Fortran Package Manager (`fpm`)**: Full asynchronous execution for `fpm build`, `fpm run`, `fpm test`, and `fpm new`.
* 🏗️ **Large Multi-File Project Intelligence**: Automatic project root detection, multi-directory `.mod`/include path discovery (`-I`), and cross-file module navigation (`:FortranFindModule`).
* ⚡ **Asynchronous Build Engine**: Non-blocking background compilation for Vim 8/9 & Neovim with dynamic multi-compiler QuickFix error parsing (`gfortran`, `ifx`, `ifort`, `nvfortran`, `flang`).
* 🎯 **Fortran Text Objects & Structural Motions**: Python/Julia-grade text objects (`vaf`/`vif` function, `vam`/`vim` module, `vat`/`vit` type, `vad`/`vid` loop) and subprogram jumps (`]m`, `[m`, `]M`, `[M`).
* 📝 **Automatic FORD & Doxygen Docstring Generator**: One-command doc generator (`:FortranDoc` / `<leader>dc`) that automatically scans parameter types, `intent(in/out/inout)`, `optional` flags, and return values.
* ⚙️ **HPC & Build Profiles Presets**: Instant switching between `Debug`, `Release`, `Fast`, and `Sanitize` profiles, with one-key OpenMP multithreading and MPI wrapper toggles (`:FortranProfile`, `:FortranOpenMP`, `:FortranMPI`).
* 🗂️ **Tagbar & Aerial Symbol Hierarchy**: Built-in Universal Ctags hierarchy (`Program` ➔ `Module` ➔ `Type` ➔ `Interface` ➔ `Subroutine`).
* 🎨 **GUI Menu with Dynamic Leader Display**: Top-level `Fortran` menu displaying exact expanded keyboard shortcuts (`\cc`, `,cc`, or `<Space>cc`).
* 🧹 **Zero-Bloat & Clean Standards**: Buffer-local mappings with complete `b:undo_ftplugin` teardown.

---

## 📦 Installation

Use your favorite Vim/Neovim plugin manager:

### [vim-plug](https://github.com/junegunn/vim-plug)
```vim
Plug 'rudrab/vimf90'
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)
```lua
use 'rudrab/vimf90'
```

### [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{ 'rudrab/vimf90', ft = 'fortran' }
```

---

## 🧩 Recommended Ecosystem & Companion Plugins

`vimf90` focuses on what it does best (build orchestration, error parsing, project navigation, text objects, and docstrings), and seamlessly pairs with established tools in the Vim/Neovim ecosystem:

| Tool / Plugin | Category | Importance | Description |
|---|---|:---:|---|
| [**fpm**](https://fpm.fortran-lang.org/) | Package Manager | **Highly Recommended** | The standard Fortran package manager & build system. |
| [**fortls**](https://github.com/gnikit/fortls) | Language Server | **Recommended** | Fortran Language Server for hover docs, signature help, and autocomplete. |
| [**fprettify**](https://github.com/pseewald/fprettify) | Formatter | **Recommended** | Auto-formatting via `:FortranFormat` or on save (`pipx install fprettify`). |
| [**vim-snippets**](https://github.com/honza/vim-snippets) / [**friendly-snippets**](https://github.com/rafamadriz/friendly-snippets) | Snippets | **Recommended** | Community standard Fortran snippets with [LuaSnip](https://github.com/L3MON4D3/LuaSnip) or [UltiSnips](https://github.com/SirVer/ultisnips). |
| [**tagbar**](https://github.com/majutsushi/tagbar) / [**aerial.nvim**](https://github.com/stevearc/aerial.nvim) | Symbol Outline | **Recommended** | Hierarchical Fortran code outliner (auto-configured by `vimf90`). |
| [**coc.nvim**](https://github.com/neoclide/coc.nvim) / **nvim-lspconfig** | LSP Client | **Recommended** | Connects Vim/Neovim to `fortls`. |
| [**vim-endwise**](https://github.com/tpope/vim-endwise) | Editing | **Optional** | Automatically adds `end` statements on Return. |

---

## ⌨️ Default Key Mappings

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
| `<leader>tg` | `<Plug>(vimf90-tags)` | Generate project Universal Ctags |
| `<leader>fm` | `<Plug>(vimf90-find-module)` | Find & jump to module definition across project |
| `<leader>dc` | `<Plug>(vimf90-doc)` | Generate FORD / Doxygen docstring header |
| `<leader>db` | `<Plug>(vimf90-ford-build)` | Build project FORD documentation (`:FordBuild`) |
| `<leader>dp` | `<Plug>(vimf90-ford-preview)` | Preview FORD documentation in browser (`:FordPreview`) |
| `<leader>pp` | `<Plug>(vimf90-profile)` | Switch / show compilation profile |
| `<leader>po` | `<Plug>(vimf90-openmp)` | Toggle OpenMP multithreading |
| `<leader>pm` | `<Plug>(vimf90-mpi)` | Toggle MPI compiler wrapper |
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

## 🛠️ User Commands

* **`fpm` Tooling**:
  * `:FortranFpm [subcmd]` / `:FortranFpmBuild` / `:FortranFpmRun [target]` / `:FortranFpmTest [target]`
  * `:FortranFpmTestCurrent`: Run only the unit test in the active buffer.
  * `:FortranFpmAdd <dependency>`: Add standard dependency (`stdlib`, `test-drive`, `lapack`, `toml-f`) to `fpm.toml`.
  * `:FortranFpmNew <name>`: Scaffold new standard Fortran package.
* **`FORD` Documentation**:
  * `:FortranDoc [ford|doxygen]`: Generate rich docstring for subroutine, function, module, type, or interface.
  * `:FordBuild`: Build project FORD documentation asynchronously.
  * `:FordPreview`: Build & open project documentation in default web browser.
* **Project Tools**:
  * `:FortranProjectBuild` / `:FortranProjectRoot` / `:FortranTags` / `:FortranFindModule <name>`
* **Compiler & HPC Profiles**:
  * `:FortranCompile` / `:FortranExe` / `:FortranRun` / `:FortranArgs` / `:FortranDebug`
  * `:FortranProfile [debug|release|fast|sanitize]`
  * `:FortranCompiler [gfortran|ifx|ifort|nvfortran|flang]`
  * `:FortranOpenMP [on|off|toggle]` / `:FortranMPI [on|off|toggle]`
* **Formatting**:
  * `:FortranFormat` (Delegates to `fprettify`)
  * `:FortranInstallDeps` (Advisory dependency helper)

---

## ⚙️ Configuration

Add these optional configurations to your `.vimrc` or `init.lua`:

```vim
" Custom leader for Fortran mappings (defaults to mapleader or '\')
let g:fortran_leader = '\'

" Set active compiler backend ('gfortran', 'ifx', 'ifort', 'nvfortran', 'flang')
let g:fortran_compiler = 'gfortran'

" Set active build profile ('debug', 'release', 'fast', 'sanitize')
let g:fortran_profile = 'debug'

" Enable async execution (Vim 8/9 & Neovim)
let g:fortran_async = 1

" Auto format buffer on save via fprettify (0: off, 1: on)
let g:fortran_format_on_save = 0

" Default docstring style ('ford' or 'doxygen')
let g:fortran_doc_style = 'ford'

" Statusline integration helper: returns e.g. '[gfortran:Debug:OMP:MPI]'
" statusline=%<%f\ %h%m%r%=%{profiles#status()}\ %-14.(%l,%c%V%)\ %P
```

---

## 🌐 Language Server Protocol (`fortls`) Setup

For `coc.nvim`, add the following to your `coc-settings.json`:
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

---

## 📜 License

GPLv3. Copyright (C) Rudra Banerjee.
