vimf90
======
**vimf90** converts vim to a fortran IDE, enhancing the development speed.

- [Introduction](#vimf90-Intro)
   - [Features](#vimf90-Features)
- [Installation](#vimf90-Inst)
- [Mappings](#vimf90-Map)
  - [construct](#vimf90-Construct)
  - [statements](#vimf90-Stats)
  - [subprograms](#vimf90-Subs)
  - [completions](#vimf90-Comp)
  - [List of available mappings](#vimf90-List)
- [Menu](#vimf90-Menu)
- [Dependencies](#vimf90-Deps)
- [Change Log](#vimf90-Clog)

Introduction
------------
This is a fortran IDE for vim. It is intended to make the coding with 
fortran easier in vim. But this is still in very nascent stage. Not 
much utility is included, and the different utility is not in sync 
properly(i.e.  different types of expansion need different key 
combinations. This is explained later).

### Features 
  * An IDE like environment for fortran 90+
  * Increases development speed considerably.
  * Easy to add new subprograms
  * Auto completion of program blocks, like if-endif etc.
  * Popup menu for standard and user defined modules and subroutines
  * Support for menu mode
  * Support for gnu-autotools (configure, make)

Installation
------------
The easiest way of installation is to use a vim plugin manager.  I
have tested it with vundle(https://github.com/gmarik/Vundle.vim)
Just add 

```bash
 Plugin 'rudrab/vimf90' 
```

in your vundle environment if you are 
already using it; or read the vundle readme for more.

Mappings
--------
#### This explains mappings of this plugin.

### construct
`if`,`do`,`select` etc statements, that are closed by a corresponding end
is defined here. After typing the first line, pressing `<F7>` will
complete the construct. For example:
 you type:
```fortran
 trial: do i=1,10<F7>        
 ```
 you will get:

 ```fortran
 trial: do i=1,10
       <cursor here>
end do trial
```

Avalable construct:
  i) `do`, ii) `if`, iii)`selectcase`, iv)`forall`, v)`type`,

NB: This part is largly copied from 
[fortran-codec0mplete](http://www.vim.org/scripts/script.php?script_id=2487)

### Statements
Some statements is included here for less typing. These are mostly
one-liner or part of the line:
you type:    |       you get
-------------|---------------
 \`wr        |        write(<cursor here>,*)<++>
 \`rd        |         read(<cursor here>,*)<++>
 \`re        |         real(<cursor here>)::<++>
 \`int       |        integer::<cursor here>
 \`ch        |         character(len=<cursor here>)::<++> 
 \`par       |                       parameter
 \`sre       |                       selected_real_kind()
 \`sie       |                       selected_integer_kind()


The `<++>` is a nice option, a `<CTRL+j>` will put your cursor in that 
position.

### subprograms
This key-combinations makes program and subprograms header.  
It supports program(`prg), module(`mod), subroutine and function. 
As shown, typing the first 3 letter and pressing <Shift-TAB>
will complete the header section of the program. e.g.
you type: 
```fortran
 `prg
 ```
 
 will yeild:
 ```fortran

         !This is file : <your file name>
         ! Author= <users login name>
         ! Started at: <current time>
         ! 
         Program  <program name you give, by default, filename>
         Implicit None
         <++Start Typing++>
         End Program  <program name you give, by default, filename>
```

### Fortran subprogram complete
vimf90 now supports subprogram completions.  `<leader>use` and
`<leader>call` will popup a list of modules and subroutine inside
present working dirs and fortran's standard module and subroutines.

### List of Mappings

Type:                             |               get:~
----------------------------------|-----------------------------------
 [name:]do[iterator]<F7>          |              do construct 
 [name:]if(condition)then<F7>     |              if construct 
 selectcase<F7>                   |              select construct 
 forall<F7>                       |              forall construct
 type::name<F7>                   |              type  construct

 
#### Program and Subprograms
Type:                             |               get:~
----------------------------------|-----------------------------------
 \`prg                            |               program header
 \`mod                            |               module header
 \`sub                            |               subroutine header
 \`fun                            |               function header

Menu
----
Menu is added for gui-help. It helps building project using 
gnu-autotool. Every fortran file will open with "Fortran90" element 
in the Menubar.
It currently has the option of Compile(Make, Make clean, build current 
file), Automake( A rudimentary configure.ac and Makefile.am file 
generator) and Programing blocks (as given in |vimf90-subs|).

Dependencies
------------
i) This plugin depends on snippets. This should work on standard
snippets engine.  I have tested it with
http://www.vim.org/scripts/script.php?script_id=2715.  
The latest version is always be found in 
https://github.com/SirVer/ultisnips
=====================================================================

Change Log
-------------
#### v0.3
        * Major update
        * Inclusion of Fortran Menu
        * Standard and inbuilt modules and subroutine pop up
        * Help with Autotool
#### v0.2
        * Major update
        * complete for subprogram
        * Formatting update
        * Major bugfixes in 
                ** Ultisnips
                ** Formats
#### v0.1.0
        *First stable, usable release
#### v0.0.2
        *Mostly maintenance release 
#### v0.0.1
        *Initial repo
