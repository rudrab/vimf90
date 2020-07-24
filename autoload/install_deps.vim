"########################################################################
" File: install_deps.vim
" Author: Rudra Banerjee (bnrj DOT rudra at gmail.com) 
" Version: 0.2
" Copyright: Copyright (C) 2019 Rudra Banerjee
" 
"    This program is free software: you can redistribute it and/or modify
"    it under the terms of the GNU General Public License as published by
"    the Free Software Foundation, either version 3 of the License, or
"    (at your option) any later version.
"
"    This program is distributed in the hope that it will be useful, 
"    but WITHOUT ANY WARRANTY; without even the implied warranty of
"    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
"    GNU General Public License for more details.
"
" Description: Install python dependencies 
"########################################################################
"
function! install_deps#install_fprettify()
  echom "Installing fprettify"
  :execute ':!pip3 install fprettify --user -q'
endfunction
function! install_deps#install_unidecode()
  echom "Installing fprettify"
  :execute ':!pip3 install unidecode --user -q'
endfunction
function! install_deps#install_fortls()
  echom "Installing fprettify"
  :execute ':!pip3 install fortran-language-server --user -q'
endfunction
