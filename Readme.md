# Introduction
- [Introduction](#introduction)
   - [Features](#features)
- [Install](#install)
   - [Dependencies](#dependencies)
- [Features](#features-1)
   - [Completions](#completions)
     - [Inbuilt](#inbuilt)
     - [Ultisnips](#ultisnips)
   - [Linting](#linting) 
   - [Menu](#menu)
- [Enable Language Server](#lsp)
- [Options](#options)
- [Contact](#contact)
- [My other apps](#my-other-apps)

This is a `fortran ide` for `vim`. It is intended to make the coding with `fortran` **easier** and
**faster** in vim.

## Features 
  * an ide like environment for fortran 90+
  * increases development speed considerably.
  * easy to add new subprograms
  * auto completion of program blocks, like `if-endif` etc.
  * popup menu for standard and user defined modules and subroutines
  * support for menu mode
  * support for gnu-autotools (configure, make)

# Major update (6th July,2020)
subroutines and modules completions are removed. It is unnecessary in the era of LSP. I have tried
and used it with [coc-nvim](https://github.com/neoclide/coc.nvim) and [fortls](https://github.com/hansec/fortran-language-server), which is working fine.

# Install
The easiest way of installation is to use a vim plugin manager. 

 * [Vundle](https://github.com/gmarik/vundle.vim)

```bash
 Plugin 'rudrab/vimf90' 
```

 * [vim-plug](https://github.com/junegunn/vim-plug)

```bash
 Plug 'rudrab/vimf90' 
```

## Dependencies
1.  **Modern vim**, tested and developed  with `8+`. Vim must be build with `python3+`
2. [Ultisnips](https://github.com/SirVer/ultisnips): (Essential) Snippetes
3. [coc-nvim](https://github.com/neoclide/coc.nvim): (Highly Recommended)
4. [language server protocol aka fortls](https://github.com/hansec/fortran-language-server)
5. [fprettify](https://github.com/pseewald/fprettify)

`fortls` and `fprettify` will be installed automatically if you enable the feature (see below.)

      
# Features
Default `leader` key used here is **`**. You can change this by using:
```vim
let g:VimF90Leader = "your chosen key"
```
in your `.vimrc`.
## Completions
There are two ways to do the completions. One is [Inbuilt Completions](#inbuilt) and
[Completions using Ultisnips](#ultisnips)

### Inbuilt 

`if`,`do`,`select` etc statements, that are closed by a corresponding `end`
is defined here. after typing the first line, pressing `<f7>` will
complete the construct. for example:
 you type:

```fortran
trial: do i=1,10<f7>        
```

you will get:

```fortran
trial: do i=1,10
  &#9014;
end do trial
```
##### Subprograms

These key-combinations makes program and subprograms header.  it supports program(\``prg`),
module(\``mod`), subroutine(\``sub`) and function(\``fun`). For example,
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

##### Constructs:

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

### Ultisnips 
Completions can also be achieved using Ultisnips (Few snippets are supplied with this code, as
ultisnips does not provide fortran snippets. **More snippets are welcome!**). `if`, `do`, `do while`
etc is inbuilt. You should define your ultisnips trigger in your vimrc(`<c-b>` here).

|Type|Get|
|-----|-----|
|`do<c-b>`|do construct|
|`if<c-b>`|if construct|


and so on. Please check `vimf90/Ultisnips/fortran.snippets` in your `.vim/` for complete list. 
(Too lazy to type all.)


<!-- ## Fortran subprogram complete -->
<!-- vimf90 now supports subprogram completions.  `<leader>use` and `<leader>call` will popup a list of -->
<!-- modules and subroutine inside present working dirs and fortran's standard module and subroutines. -->

**Update:** _Moving completions completely to `coc-nvim` and LSP implemented there. See
[dependencies](#vimf90-deps) section._ 

## Linting
Basic linting is enabled. So, when a operator is typed preceded by a space, e.g. `A =B`&#9014;, a space is
automatically inserted, yielding `A = B`&#9014;. 
This basically enables `pep8`'s whitespace rule in fortran.
You can enable/disable linting behaviour using 
```vim
let g:VimF90Linter =0/1/-1
```
where 
 *  `0`: linting as you write. But this will check every keystroke. Use cautiously. Mostly for
     testing purpose.
 *  `1`: Default. Lint only when you save a buffer
 * `-1`: Disable Linting.

For more, use dedicated linting packages like 
[fortran-language-server](https://github.com/hansec/fortran-language-server) or [ALE](https://github.com/w0rp/ale).

## Menu

Menu is added for `gui`-help. it helps building project using 
gnu-`autotool`. Every fortran file will open with `fortran90` element 
in the menubar.
it currently has the option of compile(`make`, `make clean`, `build current 
file`), `automake`( a rudimentary configure.ac and makefile.am file 
generator) and programing blocks (as given in [Subprograms](#vimf90-subs)).


# Enable Language Server

To enable language server, we need [coc-nvim](https://github.com/neoclide/coc.nvim) and [language
server protocol aka fortls](https://github.com/hansec/fortran-language-server). coc-nvim is a vim plugin, use
your favourite plugin manager to install it. For `fortls`, do
```bash
pip3 install --user fortran-language-server
```
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
      \       'command': '/home/rudra/.local/bin/fortls',
      \       'args': ['--lowercase_intrinsics'],
      \       'filetypes': ['fortran'],
      \       'rootPatterns': ['.fortls', '.git/'],
      \     }
      }
```

# Options

1. `VimF90Leader`: set your leader. default is "\`"
2. `VimF90Linter`: indent (default is `1`. `2` is preferred). Option 2 will install `fprettify`
   and `fortls`.
3. `VimF90Completer` = Completing do, if etc. Default is `<F3>`
4. `b:hl_vimf90_enable_on_vim_startup` = 1

# Contact
The preferred way of contacting me is via [github project page](https://github.com/rudrab/vimf90/issues).

# My other apps
Other apps I have developed:

- [MkBiB](http://rudrab.github.io/mkbib/): BibTeX maker.

- [Periodic Table](http://rudrab.github.io/periodictable/): Modern Periodic Table based on Gtk-3

- [Shadow](http://rudrab.github.io/Shadow/): Icon theme for Linux desktop

- [Dual](http://rudrab.github.io/dual/) : Icon theme for Linux desktop

- [Vimf90](http://rudrab.github.io/vimf90/): Fortran Plugin for vim
