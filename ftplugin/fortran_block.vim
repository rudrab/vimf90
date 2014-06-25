" File: block.vim
" Author: Rudra Banerjee (bnrj DOT rudra at gmail.com) 
" Version: 0.1
" Copyright: Copyright (C) 2014 Rudra Banerjee
" THIS FILE IS AN UPDATE OF fortran_codecomplete.vim
" (http://www.vim.org/scripts/script.php?script_id=2487) BY Michael Goerz
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
" Description: 
"    This maps the <F7> key to complete Fortran 90 constructs"



python << EOF
import re
import vim

class SyntaxElement:
    def __init__(self, pattern, closingline):
        self.pattern = pattern
        self.closingline = closingline
    def match(self, line): 
        """ Return (indent, closingline) or (None, None)"""
        match = self.pattern.search(line)
        if match:
            indentpattern = re.compile(r'^\s*')
            variablepattern = re.compile(r'\$\{(?P<varname>[a-zA-Z0-9_]*)\}')
            indent = indentpattern.search(line).group(0)
            closingline = self.closingline
            # expand variables in closingline
            while True:
                variable_match = variablepattern.search(closingline)
                if variable_match:
                    try:
                        replacement = match.group(variable_match.group('varname'))
                    except:
                        print "Group %s is not defined in pattern" % variable_match.group('varname')
                        replacement = variable_match.group('varname')
                    try:
                        closingline = closingline.replace(variable_match.group(0), replacement)
                    except TypeError:
                        if replacement is None:
                            replacement = ""
                        closingline = closingline.replace(variable_match.group(0), str(replacement))
                else:
                    break
        else:
            return (None, None)
        closingline = closingline.rstrip()
        return (indent, closingline)
            
        
def fortran_complete():

    syntax_elements = [
        SyntaxElement(re.compile(r'^\s*((?P<name>([a-zA-Z0-9_]+))\s*:)?\s*if\s*\(.*\)\s*then'),
                      'end if ${name}' ),
        SyntaxElement(re.compile(r'^\s*((?P<name>([a-zA-Z0-9_]+))\s*:)?\s*do'),
                      'end do ${name}' ),
        SyntaxElement(re.compile(r'^\s*select\s*case\s*'),
                      'end select' ),
        SyntaxElement(re.compile(r'^\s*forall\s*'),
                      'end forall' ),
        SyntaxElement(re.compile(r'\s*open\((?:unit\s*=\s*?)((?P<name>([0-9]+))),.*\)'),
                      'close(${name})' ),                           
        SyntaxElement(re.compile(r'^\s*?\s*type\s*::((?P<name>([a-zA-Z0-9_]+))\s*)'),
                      'end typE ${name}' )
    ]

    cb = vim.current.buffer
    line = vim.current.window.cursor[0] - 1
    cline = cb[line]

    for syntax_element in syntax_elements:
        (indent, closingline) = syntax_element.match(cline)
        if closingline is not None:
            vim.command('s/$/\x0D\x0D/') # insert two lines
            vim.command('nohls') # insert two lines
            shiftwidth = int(vim.eval("&shiftwidth"))
            cb[line+1] = indent + (" " * shiftwidth)
            cb[line+2] = indent + closingline 
            vim.current.window.cursor = (line+2, 1)
EOF

nmap <F7> :python fortran_complete()<cr>A
imap <F7> :python fortran_complete()<cr>A
