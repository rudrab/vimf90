"########################################################################
" File:          ftplugin/fortran_block.vim
" Author:        Rudra Banerjee (bnrj DOT rudra at gmail.com)
" Version:       0.3
" License:       GPLv3
" Description:   Smart construct auto-completion for Fortran 90+
"########################################################################

if !has('python3')
  finish
endif

" Define Python completion engine only once
if !exists('g:loaded_vimf90_py')
  let g:loaded_vimf90_py = 1
python3 << EOF
import re
import vim

class SyntaxElement:
    def __init__(self, opening_pattern, closing_template):
        self.opening_pattern = opening_pattern
        self.closing_template = closing_template

    def match(self, line):
        """Return (indent, closing_line) or (None, None)"""
        match = self.opening_pattern.search(line)
        if not match:
            return (None, None)

        indent = re.match(r'^\s*', line).group(0)
        matched_text = match.group(0).strip()
        closing_line = self.closing_template

        # Match keyword casing with user's code
        if matched_text.isupper():
            closing_line = closing_line.upper()
        elif matched_text.islower():
            closing_line = closing_line.lower()
        elif matched_text.istitle():
            closing_line = closing_line.title()

        # Substitute named capture groups (case-insensitive placeholder)
        var_pattern = re.compile(r'\$\{(?P<varname>[a-zA-Z0-9_]+)\}', re.IGNORECASE)
        for var_match in list(var_pattern.finditer(closing_line)):
            var_name = var_match.group('varname').lower()
            try:
                replacement = match.group(var_name) or ""
            except (IndexError, IndexError):
                replacement = ""
            closing_line = closing_line.replace(var_match.group(0), replacement)

        return (indent, closing_line.strip())


def fortran_complete_block():
    elements = [
        SyntaxElement(
            re.compile(r'^\s*program\s+(?P<name>[a-zA-Z0-9_]+)', re.IGNORECASE),
            'end program ${name}'
        ),
        SyntaxElement(
            re.compile(r'^\s*module\s+(?P<name>[a-zA-Z0-9_]+)', re.IGNORECASE),
            'end module ${name}'
        ),
        SyntaxElement(
            re.compile(r'^\s*(?:[a-zA-Z0-9_()]+\s+)*function\s+(?P<name>[a-zA-Z0-9_]+)', re.IGNORECASE),
            'end function ${name}'
        ),
        SyntaxElement(
            re.compile(r'^\s*(?:recursive\s+|pure\s+|elemental\s+)*subroutine\s+(?P<name>[a-zA-Z0-9_]+)', re.IGNORECASE),
            'end subroutine ${name}'
        ),
        SyntaxElement(
            re.compile(r'^\s*(?:(?P<name>[a-zA-Z0-9_]+)\s*:\s*)?if\s*\(.*\)\s*then', re.IGNORECASE),
            'end if ${name}'
        ),
        SyntaxElement(
            re.compile(r'^\s*(?:(?P<name>[a-zA-Z0-9_]+)\s*:\s*)?do\b', re.IGNORECASE),
            'end do ${name}'
        ),
        SyntaxElement(
            re.compile(r'^\s*select\s+case\s*\(', re.IGNORECASE),
            'end select'
        ),
        SyntaxElement(
            re.compile(r'^\s*select\s+type\s*\(', re.IGNORECASE),
            'end select'
        ),
        SyntaxElement(
            re.compile(r'^\s*forall\s*\(', re.IGNORECASE),
            'end forall'
        ),
        SyntaxElement(
            re.compile(r'^\s*where\s*\(.*\)\s*$', re.IGNORECASE),
            'end where'
        ),
        SyntaxElement(
            re.compile(r'^\s*open\s*\(\s*(?:unit\s*=\s*)?(?P<unit>[0-9]+)', re.IGNORECASE),
            'close(${unit})'
        ),
        SyntaxElement(
            re.compile(r'^\s*type\s*(?:::)?\s*(?P<name>[a-zA-Z0-9_]+)\s*$', re.IGNORECASE),
            'end type ${name}'
        ),
        SyntaxElement(
            re.compile(r'^\s*interface\s*(?P<name>[a-zA-Z0-9_]+)?', re.IGNORECASE),
            'end interface ${name}'
        ),
        SyntaxElement(
            re.compile(r'^\s*block\s*(?P<name>[a-zA-Z0-9_]+)?', re.IGNORECASE),
            'end block ${name}'
        ),
    ]

    cb = vim.current.buffer
    cursor_row, cursor_col = vim.current.window.cursor
    line_idx = cursor_row - 1
    current_line = cb[line_idx]

    for elem in elements:
        indent, closing = elem.match(current_line)
        if closing is not None:
            sw = int(vim.eval("&shiftwidth") or 2)
            if sw <= 0:
                sw = int(vim.eval("&tabstop") or 2)
            body_indent = indent + (" " * sw)
            closing_line = (indent + " " + closing.strip()).rstrip() if indent else closing.strip()

            # Insert body line and end line
            cb.append([body_indent, closing_line], line_idx + 1)
            # Position cursor inside the block
            vim.current.window.cursor = (cursor_row + 1, len(body_indent))
            break
EOF
endif

function! s:fortran_complete() abort
  if has('python3')
    python3 fortran_complete_block()
  endif
endfunction

" Plug mappings
nnoremap <buffer> <silent> <Plug>(vimf90-construct-complete) :call <SID>fortran_complete()<CR>A
inoremap <buffer> <silent> <Plug>(vimf90-construct-complete) <Esc>:call <SID>fortran_complete()<CR>A

let b:fortran_completer = get(g:, 'fortran_completer', '<F3>')
if !empty(b:fortran_completer)
  execute 'nmap <buffer> <silent>' b:fortran_completer '<Plug>(vimf90-construct-complete)'
  execute 'imap <buffer> <silent>' b:fortran_completer '<Plug>(vimf90-construct-complete)'
endif

if !exists('g:loaded_matchit') && findfile('plugin/matchit.vim', &runtimepath) ==# ''
  silent! packadd matchit
endif

" Undo ftplugin
let s:undo = 'unlet! b:fortran_completer | silent! nunmap <buffer> <Plug>(vimf90-construct-complete) | silent! iunmap <buffer> <Plug>(vimf90-construct-complete)'
if !empty(b:fortran_completer)
  let s:undo .= ' | silent! nunmap <buffer> ' . b:fortran_completer . ' | silent! iunmap <buffer> ' . b:fortran_completer
endif
let b:undo_ftplugin = (exists('b:undo_ftplugin') ? b:undo_ftplugin . ' | ' : '') . s:undo
