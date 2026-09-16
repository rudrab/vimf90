# VimF90 Architecture & Design Philosophy

## Vision
`vimf90` is designed to be the **indispensable, modern Vim/Neovim development environment for scientific Fortran**.

---

## Non-Negotiable Core Directives

All future development, AI assistants, and contributors MUST adhere to the following principles:

### 1. Modern Standards as First-Class Citizens
* **Build System**: **`fpm` (Fortran Package Manager)** is the primary project and package management standard for `vimf90`. All new build and scaffolding features must prioritize `fpm`.
* **Documentation**: **`FORD` (Fortran Documenter)** is the primary documentation engine.
* **Modern Standards**: Focus on Modern Fortran (Fortran 2008, 2018, 2023) and High-Performance Scientific Computing (HPC, OpenMP, MPI, Coarrays).
* **Coarrays are Native Language Syntax**: Coarrays are standard ISO Fortran syntax (F2008/F2018/F2023), not an external add-on library. Compiler presets natively include coarray flags (e.g., `-fcoarray=single` for `gfortran`) without requiring a separate "CAF mode" or segregated command namespace.

### 2. Legacy Methods Frozen
* **No effort on GNU Autotools**: Autotools scaffolding (`configure.ac`, `Makefile.am`) is deprecated and must not be developed further.
* **Legacy Make**: Standard `make` is preserved strictly as a read-only historical fallback for existing `Makefile` repositories.
* **No legacy Doxygen formatting**: Doc generation standardizes around FORD markdown.

### 3. Zero-Bloat & Ecosystem Hygiene
* **No Snippet Bundling**: Snippets belong in dedicated community collections (`honza/vim-snippets`, `friendly-snippets`).
* **No Embedded Python Runtimes**: Keep plugin lightweight and dependency-free.
* **No Insert-Mode Key Hijacking**: Never hijack arithmetic operators (`=`, `+`, `*`, `/`) in insert mode.
* **Buffer Isolation**: All mappings, commands, autocommands, and options must be strictly scoped to `<buffer>` with complete `b:undo_ftplugin` teardown.
