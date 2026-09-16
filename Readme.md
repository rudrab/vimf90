* [Introduction](#introduction)
  * [Features](#features)
* [Install](#install)
  * [Dependencies](#dependencies)
* [Options](#options)
* [Features](#features-1)
  * [Completions](#completions)
    * [Inbuilt (completed using `fortran_leader`)](#inbuilt-completed-using-fortran_leader)
      * [Constructs](#constructs)
      * [Statements](#statements)
      * [Subprograms (completed using `fortran_completor`)](#subprograms-completed-using-fortran_completor)
    * [Ultisnips](#ultisnips)
  * [Linting (Controlled by `fortran_linter`)](#linting-controlled-by-fortran_linter)
  * [Compile and Autotool Support](#compile-and-autotool-support)
      * [Available compilation options](#available-compilation-options)
    * [Menu](#menu)
  * [Language Server Protocol](#language-server-protocol)
* [Contact](#contact)
* [My other apps](#my-other-apps)

<!-- vim-markdown-toc -->

<!-- Introduction {{{1 -->
## Introduction    
 `fortran` `ide` for `vim`. It is intended to make the coding with `fortran` **easier** and
**faster** in vim.
### Features 
  * An ide like environment for fortran 90+
  * Supports LSP
  * Increases development speed considerably.
  * Easy to add new subprograms
  * Auto completion of program blocks, like `if-endif` etc.
  * Popup menu for standard and user defined modules and subroutines
  * Support for menu mode
  * Support for gnu-autotools (configure, make)
      
<!-- }}} -->

<!-- Install {{{1 -->
## Install
The easiest way of installation is to use a vim plugin manager. 

 * [Vundle](https://github.com/gmarik/vundle.vim)

```bash
 Plugin 'rudrab/vimf90' 
```

 * [vim-plug](https://github.com/junegunn/vim-plug)

```bash
 Plug 'rudrab/vimf90' 
```

### Dependencies
1.  **Modern vim**, tested and developed  with `8+`. Vim must be build with `python3+`
2. [Ultisnips](https://github.com/SirVer/ultisnips): (Essential) Snippetes.
4. [language server protocol aka fortls](https://github.com/hansec/fortran-language-server): Highly
   recommended.
3. [coc-nvim](https://github.com/neoclide/coc.nvim): Recommended to use
   [fortls](https://github.com/hansec/fortran-language-server).
5. [fprettify](https://github.com/pseewald/fprettify).

`fortls` and `fprettify` will be installed automatically if you enable the feature (see below.)
}}}1

## Options
There are several options to configure how `VimF90` will work. 

1. `fortran_leader`: Set your leader. Default is "\`"
2. `fortran_linter`: Rudimentary linting (unless you use `2`). Default is `1`. `2` is preferred).
   Option 2 will install `fprettify` and `fortls`. For a better linting, you should use a dedicated
   package like `ALE` or `coc.nvim`.
3. `fortran_completer`: Completing do, if etc. Default is `<F3>`.
4. `fprettify_options`: Works only with `fortran_linter=2`. Check `fprettify --help` for available
   options. Default is `--silent`.

## Features
Default `leader` key used here is **\`**. You can change this by using:
```vim
let fortran_leader = "your chosen key"
```
in your `.vimrc`.
### Completions
There are two ways to do the completions. One is [Inbuilt Completions](#inbuilt) and
[Completions using Ultisnips](#ultisnips)

#### Inbuilt (completed using `fortran_leader`) 
`if`,`do`,`select` etc statements, that are closed by a corresponding `end`
is defined here. after typing the first line, pressing `<F3>` will
complete the construct. for example:
 you type:

```fortran
trial: do i=1,10<F3>        
```

you will get:

```fortran
trial: do i=1,10
  &#9014;
end do trial
```

##### Constructs

|type:                         |   get               |
|------------------------------|---------------------|
|`[name:]do[iterator]<f7>`       |  do construct |
|`[name:]if(condition)then<f7>`  |  if construct |
|`selectcase<f7>`                |  select construct |
|`forall<f7>`                    |  forall construct|
|`type::name<f7>`                |  type  construct|

**NB**: this part is shamelessly copied from 
[fortran-codecomplete](http://www.vim.org/scripts/script.php?script_id=2487)


##### Statements

Some statements is included here for less typing. these are mostly one-liner or part of the line:

|you type:    |       you get|
|-------------|---------------|
|\`wr        |   write(&#9014;,*)<++>|
|\`rd        |   read(&#9014;,*)<++>|
|\`re        |   real(&#9014;)::<++>|
|\`int       |   integer(&#9014;)::<++>|
|\`ch        |   character(len=&#9014;)::<++> |
|\`par       |   parameter|
|\`sre       |   selected_real_kind(&#9014;)|
|\`sie       |   selected_integer_kind(&#9014;)|


The `<++>` is a nice option, a `<c-j>` will put your cursor in that position. Use 

 ```vim
 inoremap <c-j> <Esc>/<++><CR><Esc><cf>
 ```

in your `.vimrc` for this feature.


##### Subprograms (completed using `fortran_completor`)
These key-combinations makes program and subprograms header.  It supports program(**\`prg**),
module(**\`mod**), subroutine(**\`sub**) and function(**\`fun**). The initiator \` can be changed using
`fortran_leader` (See [Options](#options) for more). For example,
```bash
`prg
```
will yeild:

```fortran
!this is file : <your file name>
! author= <users login name>
! started at: <current time>
! 
program  <filename>
implicit none
  <++start typing++>
end program  <filename>
```

###### available constructs

|type: |     get:|
|------|---------|
|\`prg |    program header |
|\`mod |    module header|
|\`sub |    subroutine header|
|\`fun |    function header|

#### Ultisnips 
Completions can also be achieved using Ultisnips (Few snippets are supplied with this code, as
ultisnips does not provide fortran snippets. **More snippets are welcome!**). `if`, `do`, `do while`
etc is inbuilt. You should define your ultisnips trigger in your vimrc(`<c-b>` here).

|Type|Get|
|-----|-----|
|`do<c-b>`|do construct|
|`if<c-b>`|if construct|


and so on. Please check `vimf90/Ultisnips/fortran.snippets` in your `.vim/` for complete list. 
(Too lazy to type all.)

**NB**: Kindly consider submitting your `snippets` as pull request. This will help me enhance my
snippets.


<!-- ### Fortran subprogram complete -->
<!-- vimf90 now supports subprogram completions.  `<leader>use` and `<leader>call` will popup a list of -->
<!-- modules and subroutine inside present working dirs and fortran's standard module and subroutines. -->
<!-- **Update:** Moving completions completely to `coc-nvim` and LSP implemented there. See -->
<!-- \[dependencies](#vimf90-deps) section. -->

### Linting (Controlled by `fortran_linter`)
Basic linting is enabled. So, when a operator is typed preceded by a space, e.g. `A =B`&#9014;, a space is
automatically inserted, yielding `A = B`&#9014;. 
This basically enables python's `pep8-like` whitespace rule in fortran.
You can enable/disable linting behaviour using 
```vim
let fortran_linter =0/1/2/-1
```
where 
 *  `0`: linting as you write. But this will check every keystroke. Use cautiously. Mostly for
     testing purpose.
 *  `1`: Default. Lint only when you save a buffer
 *  `2`: **Strongly recommended**. Other options are there because I don't want to force you to install
     `fprettify`. This will automatically install `fortls` too. Modify fprettify options with
     `fprettify_optios`. 
 * `-1`: Disable Linting.

For more, use dedicated linting packages like `fortls` or [ALE](https://github.com/w0rp/ale).

### Fortran Package Manager (fpm) Support

`vimf90` includes first-class support for modern [fpm](https://fpm.fortran-lang.org/):

* `<leader>fb` or `:FortranFpmBuild [args]`: Compile the whole fpm project asynchronously.
* `<leader>fr` or `:FortranFpmRun [args]`: Run the fpm application.
* `<leader>ft` or `:FortranFpmTest [args]`: Run all unit tests.
* `:FortranFpmNew <name>`: Create a new standard Fortran project template.
* `:FortranFpm <command>`: Generic fpm runner with tab-completion.

### Large Multi-File Project Support

For large Fortran projects (spanning hundreds of modules across subdirectories):

1. **Automatic Root Detection**: Finds `fpm.toml`, `CMakeLists.txt`, `meson.build`, `Makefile`, or `.git` up the directory tree.
2. **Automatic Module (`.mod`) Path Resolution**: Automatically discovers include and `.mod` directories in `src/`, `include/`, `build/`, `build/gfortran_*` and injects `-I` flags into compilation.
3. **Project-Wide Universal Ctags**: Run `<leader>tg` or `:FortranTags` to generate tags across all modules, subroutines, and types.
4. **Module Navigation**: Run `<leader>fm` or `:FortranFindModule <name>` to jump to the file defining any module across the project.
5. **Universal Project Build**: `:FortranProjectBuild` automatically builds using the detected build tool (`fpm`, `CMake`, `Make`).

### Compile and Autotool Support
Some build and [GNU autotool](https://www.gnu.org/software/automake/) features are added. 
You can configure the options to your tastes.
##### Available compilation options
###### variables
* `fortran_compiler`: Set fortran compiler. Default is `gfortran` (supports `ifx`, `ifort`, `nvfortran`, `flang`)
* `fortran_async`: Enable background non-blocking compilation for Vim 8+ and Neovim. Default is `1`.
* `fortran_run_terminal`: Run apps/debuggers in a bottom terminal split. Default is `0`.
* `fortran_exeExt`: Executable Extension. Default is `''`.
* `fortran_fcflags`: Compiler options. Default is `-Wall  -O0 -c `
* `fortran_flflags`: Compiler options. Default is `-Wall  -O0 `
###### Keyboard shortcuts (Your current options are visible in `menu`)
* `fortran_compile`: Compile current buffer. Default is `<leader>cc`
* `fortran_exe`: Create the executable, without running it. Default in `<leader>ce`
* `fortran_run`: Compile and run current buffer. Default is `<leader>cr`
* `fortran_cla`: Command Line Arguments for compile and run current buffer. Default is `<leader>cl`
* `fortran_dbg`: Debug current buffer. Default is `<leader>cd`
* `fortran_make`: Make if makefile exists. Default is `<leader>mk`
* `fortran_makeProp`: CLA to make. Default is `<leader>mp`
* `fortran_genProj`: Creates a gnu style project structure. Default is `<leader>gp`
* `fortran_fpm_build`: fpm build. Default is `<leader>fb`
* `fortran_fpm_run`: fpm run. Default is `<leader>fr`
* `fortran_fpm_test`: fpm test. Default is `<leader>ft`
* `fortran_tags`: Generate project Ctags. Default is `<leader>tg`
* `fortran_find_mod`: Find module across project. Default is `<leader>fm`

#### Menu
Menu is added for `gui`-help. Every fortran file will open with `fortran90` element in the menubar.
It provides options for compile (`make`, build current file, `fpm`), autotools, and programming blocks.


### Language Server Protocol 

To enable language server, we need [coc-nvim](https://github.com/neoclide/coc.nvim) and [language
server protocol aka fortls](https://github.com/hansec/fortran-language-server). coc-nvim is a vim
plugin, use your favourite plugin manager to install it. `fortls` is automatically installed if
`fortran_linter=2`).

An example `vimrc` for `fortls` using `coc-nvim` is shown here

```vim
let g:coc_start_at_startup = 0
augroup coc
  autocmd!
  autocmd VimEnter * :silent CocStart
augroup end

let g:coc_user_config = {
      \   'languageserver': {
      \     'fortran': {
      \       'command': 'fortls',
      \       'args': ['--lowercase_intrinsics'],
      \       'filetypes': ['fortran'],
      \       'rootPatterns': ['.fortls', '.git/']
      \     }
      \   }
      \ }
```


## Contact
The preferred way of contacting me is via [github project page](https://github.com/rudrab/vimf90/issues).

## My other apps
Other apps I have developed:

- [MkBiB](http://rudrab.github.io/mkbib/): BibTeX maker.

- [Periodic Table](http://rudrab.github.io/periodictable/): Modern Periodic Table based on Gtk-3

- [Shadow](http://rudrab.github.io/Shadow/): Icon theme for Linux desktop

- [Dual](http://rudrab.github.io/dual/) : Icon theme for Linux desktop

- [Vimf90](http://rudrab.github.io/vimf90/): Fortran Plugin for vim
