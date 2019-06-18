Introduction
============
**vimf90** enhances coding fortran in vim. It increases code-development speed.

- [Introduction](#vimf90-intro)
   - [Features](#vimf90-features)
- [Installation](#vimf90-inst)
   - [Dependency](#vimf90-deps)
- [Mappings](#vimf90-map)
  - [Construct](#vimf90-construct)
  - [Statements](#vimf90-stats)
  - [Subprograms](#vimf90-subs)
  - [Completions](#vimf90-comp)
- [Menu](#vimf90-menu)
- [Contact](#contact)
- [My other apps](#apps)

This is a `fortran` `ide` for `vim`. It is intended to make the coding with `fortran` **easier** and
**faster** in vim.

Features 
----------
  * an ide like environment for fortran 90+
  * increases development speed considerably.
  * easy to add new subprograms
  * auto completion of program blocks, like `if-endif` etc.
  * popup menu for standard and user defined modules and subroutines
  * support for menu mode
  * support for gnu-autotools (configure, make)

Installation
============
the easiest way of installation is to use a vim plugin manager. 

 * [Vundle](https://github.com/gmarik/vundle.vim)

```bash
 Plugin 'rudrab/vimf90' 
```

 * [vim-plug](https://github.com/junegunn/vim-plug)

```bash
 Plug 'rudrab/vimf90' 
```

### Dependencies
1. [Ultisnips](https://github.com/SirVer/ultisnips): (Essential) Snippetes
2. [coc-nvim](https://github.com/neoclide/coc.nvim): (Optional, but highly recommended)
      Autocompletion and [language server
      protocol](https://github.com/hansec/fortran-language-server). Check further dependencies
      [here](https://github.com/neoclide/coc.nvim/wiki/Language-servers#fortran).

Mappings
========

Construct
---------

There are two ways to do the completions. One is [Inbuilt Completions](#vimf90-inbuilt) and
[Completions using Ultisnips](#vimf90-ultisnips)
### i. Inbuilt completions

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
  <cursor here>
end do trial
```


#### Constructs:

|type:                         |   get               |
|------------------------------|---------------------|
|`[name:]do[iterator]<f7>`       |  do construct |
|`[name:]if(condition)then<f7>`  |  if construct |
|`selectcase<f7>`                |  select construct |
|`forall<f7>`                    |  forall construct|
|`type::name<f7>`                |  type  construct|

**NB**: this part is shamelessly copied from 
[fortran-codecomplete](http://www.vim.org/scripts/script.php?script_id=2487)


#### Statements

some statements is included here for less typing. these are mostly
one-liner or part of the line:

|you type:    |       you get|
|-------------|---------------|
|\`wr        |   write(<cursor here>,*)<++>|
|\`rd        |   read(<cursor here>,*)<++>|
|\`re        |   real(<cursor here>)::<++>|
|\`int       |   integer::<cursor here>|
|\`ch        |   character(len=<cursor here>)::<++> |
|\`par       |   parameter|
|\`sre       |   selected_real_kind()|
|\`sie       |   selected_integer_kind()|


The `<++>` is a nice option, a `<c-j>` will put your cursor in that position. Use 

 ```vim
 inoremap <c-j> <Esc>/<++><CR><Esc><cf>
 ```

 in your `.vimrc` for this feature.

### ii. Completions using Ultisnips 
Completions can also be achieved using Ultisnips (Few snippets are supplied with this code, as
ultisnips does not provide fortran snippets. **More snippets are welcome!**). `if`, `do`, `do while`
etc is inbuilt. 

Subprograms
-----------

These key-combinations makes program and subprograms header.  it supports program(`prg),
module(`mod), subroutine and function.  as shown, typing the first 3 letter and pressing **\`**
will complete the header section of the program. This can also be achieved by Ultisnips, as: you
type: 

```bash
`prg
```
or 

 ```bash
 prg <Your Ultisnip Trigger>
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

### available constructs

|type: |     get:|
|------|---------|
|\`prg |    program header |
|\`mod |    module header|
|\`sub |    subroutine header|
|\`fun |    function header|

Fortran subprogram complete
---------------------------
vimf90 now supports subprogram completions.  `<leader>use` and
`<leader>call` will popup a list of modules and subroutine inside
present working dirs and fortran's standard module and subroutines.
**Update:** _Moving completions competely to `coc-nvim` and LSP implemented there. See
[dependencies](#vimf90-deps) section._ 

Menu
====
**menu** is added for `gui`-help. it helps building project using 
gnu-`autotool`. Every fortran file will open with `fortran90` element 
in the menubar.
it currently has the option of compile(`make`, `make clean`, `build current 
file`), `automake`( a rudimentary configure.ac and makefile.am file 
generator) and programing blocks (as given in [Subprograms](#vimf90-subs)).

<!-- Dependencies -->
<!-- ============ -->
<!-- - this plugin depends on snippets. this should work on standard -->
<!-- snippets engine.  I have tested it with [ultisnips](https://github.com/sirver/ultisnips). -->


Contacts
========
the preferred way of contacting me is via [github project page](https://github.com/rudrab/vimf90/issues).


My other apps
=============
Other apps I have developed:

- [MkBiB](http://rudrab.github.io/mkbib/): BibTeX maker.

- [Periodic Table](http://rudrab.github.io/periodictable/): Modern Periodic Table based on Gtk-3

- [Shadow](http://rudrab.github.io/Shadow/): Icon theme for Linux desktop

- [Dual](http://rudrab.github.io/dual/) : Icon theme for Linux desktop

- [Vimf90](http://rudrab.github.io/vimf90/): Fortran Plugin for vim
